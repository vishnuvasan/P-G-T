import os
import os.path
import uuid
import shutil
import csv

from bottle import  template, route,  get, post, request, response, redirect, BaseRequest

from pgtools.constants import *
from pgtools.config import *
from pgtools.workflows import *
from pgtools.util import *
from pgtools.runs import *
from pgtools.db import *


@route( '/view/:view_id')
def view( view_id ):
  errors = [ ]
  view   = Runs().find( view_id )

  if view[ 'kind' ] in [ 'decoy', 'translate', 'annotate', 'convert', 'proteome_run', 'genome_run' ]:
    return globals().get( view[ 'kind' ] + '_view' )( view )


def decoy_view( view ):
  ifile, ofile, directory = view[ 'input_filename' ], view[ 'output_filename' ], view[ 'local_directory' ]
  stdout, stderr = os.path.join( directory, 'stdout' ), os.path.join( directory, 'stderr' )

  if view[ 'kind' ] == 'annotate':

    if ifile.endswith( '.csv' ):
      input_sample = table( ifile )
    else:
      input_sample = cat( ifile )

    output_sample = table( ofile )
  else:
    input_sample, output_sample = head( ifile, 25), head( ofile, 25)

  print cat( stdout )

  return template( 'templates/view', 
    view=view,
    input_sample=input_sample,
    output_sample=output_sample,
    error_log=cat( stderr ),
    stdout=cat( stdout ),
    command=view['command']
  )


# use same as decoy view
def translate_view( view ):
  return decoy_view( view )

def convert_view( view ):
  return decoy_view( view )


def annotate_view( view ):
  return decoy_view( view )

def proteome_run_view( view ):
  return complete_run_view( view )

def genome_run_view( view ):
  complete_run_details = get_genome_run_details( view )
  return template( 'templates/view/genome_run', view=view, types=get_types(),  config_error=0, **complete_run_details )

def complete_run_view( view ):
  complete_run_details = get_complete_run_details( view ) 
  return template( 'templates/view/complete_run', view=view, types=get_types(),  config_error=0, **complete_run_details )

def head( filename, number_lines=100 ):

  if not os.path.isfile( filename ):
    return ''

  lines = [ ]

  count = 0
  for line in open( filename ):
    count += 1

    if count == number_lines:
      break

    lines.append( line )


  return "\n".join( lines )


def cat( filename ):
  return "\n".join( open( filename ).readlines() )

def table( filename ):
  csvfile = open( filename, 'rb' )
  reader = csv.reader( csvfile )
  rows = [ ]

  for row in reader:
    rows.append( row )

  return rows

def get_db_directory( view ):
  directory = view[ 'local_directory' ]
  run_directory = _get_first_directory( os.path.join( directory, 'scratch' ) )
  config = json.load( file( os.path.join( directory, 'config.json') ) )

  db_directory = None
  for i in config[ 'phase2_databases'].keys():
    print "DOING: " + i
    if i in view[ 'command' ]:
      print "EXISTS!"
      print run_directory
      to_check =   os.path.join( run_directory, os.path.splitext( os.path.basename( config[ 'phase2_databases'][ i ] ) )[ 0 ] )
      print "CHECKING FOR: " + to_check
      if os.path.isdir( to_check ):
        print "FOUND"
        db_directory = to_check 

  return db_directory

def _get_first_directory( path ):
  items = filter( lambda x: os.path.isdir( os.path.join( path, x ) ), os.listdir( path ) )

  print items

  if len( items ) > 0:
    return os.path.join( path, items[ 0 ] )

  return None


def get_genome_run_details( view ):
  directory = view[ 'local_directory' ]
  run_directory = _get_first_directory( os.path.join( directory, 'scratch' ) )
  config = json.load( file( os.path.join( directory, 'config.json') ) )

  db_directory = get_db_directory( view )
  actual_scratch_directory = _get_first_directory( db_directory )
  status_file = os.path.join( db_directory, 'current_status.json')


  try:
    current_status = beautify_json( status_file ) 
  except:
    current_status = ''

  summary_file = os.path.join( db_directory, '..', 'summary.html' )

  return {
    'configuration': beautify_json( os.path.join( directory, 'config.json' ) ),
    'is_summary': os.path.isfile( summary_file ),
    'summary_file': summary_file,
    'config': config,
    'error_log': cat( os.path.join( directory, 'stderr') ),
    'stdout': cat( os.path.join( directory, 'stdout') ),
    'run_status': current_status,
  }



def get_complete_run_details( view ):
  directory = view[ 'local_directory' ]
  run_directory = os.path.join( directory, 'scratch', os.listdir( os.path.join( directory, 'scratch') )[ 0 ] )
  current_status = None
  config = json.load( file( os.path.join( directory, 'config.json') ) )

  try:
    current_status_file = os.path.join( run_directory, 'current_status.json') 
    current_status = beautify_json( current_status_file ) 

  except:
    current_status = ''

  summary_file = os.path.join( run_directory, 'summary.html' )
  summary_file_exists = os.path.isfile( summary_file )

  return {
    'configuration': beautify_json( os.path.join( directory, 'config.json' ) ),
    'is_summary': summary_file_exists,
    'summary_file': summary_file,
    'config': config,
    'error_log': cat( os.path.join( directory, 'stderr') ),
    'stdout': cat( os.path.join( directory, 'stdout') ),
    'run_status': current_status,
  }


def beautify_json( filename ):
  return json.dumps( json.load( open( filename ) ), indent=2 )

def _get_class( config, search_type ):

  for item in config[ 'msearch' ][ 'algorithms' ]:
    if item[ 'name' ] == search_type:
      return item[ 'class' ]

  return None

def _get_file_data( filename ):
  if os.path.exists( filename ) and os.path.isfile( filename ):
    return {
        'file': filename,
        'count': count_lines( filename ),
        'table': table( filename )
    }
  else:
    return None


def search_and_fdr( run_directory, config ):
  items = config[ 'msearch' ][ 'defaults']
  data = { }

  for search_type in items:

    data[ search_type ] = current = { }

    search_class  = _get_class( config, search_type )
    directory     = os.path.join( run_directory, search_class )

    # target, decoy and filtered in that order
    files = get_search_files( directory )
    types = [ 'target', 'decoy', 'filtered' ]

    for i in range( len( types ) ):
      _type = types[ i ]
      _file = files[ i ]

      current[ _type ] = current_run = { }

      if _file and os.path.exists( _file ) and os.path.isfile( _file ):
        current_run[ 'file' ] = _file 
        current_run[ 'count' ] = count_lines( _file ) 
        current_run[ 'table' ] = table( _file )[ 0:50 ] 
      else:
        current_run[ 'file' ] = _file 
        current_run[ 'count' ] = 0 
        current_run[ 'table' ] = [ ] 

  return data

    
def count_lines( filename ):
  if os.path.exists( filename ) and os.path.isfile( filename ):
    return len( file( filename ).readlines() )
  else: 
    return None


def get_search_files( directory ):
  result = [ ]

  for file_type in [ 'target', 'decoy', 'filtered' ]:

    files = [ 
      os.path.join( directory, i ) 
        for i in os.listdir( directory )
        if file_type + '.csv' in i
    ]

    result.append( files[ 0 ] if len( files ) > 0 else None )


  return result


