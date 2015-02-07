import os
import os.path
import uuid
import shutil

from bottle import  template, route,  get, post, request, response, redirect, BaseRequest

from pgtools.constants import *
from pgtools.config import *
from pgtools.workflows import *
from pgtools.util import *
from pgtools.runs import *

from pgtools.db import Runs

@route( '/workflow/:workflow_name' )
def workflow( workflow_name ):
  return template( 'templates/workflow', wf=get_all_workflows(), current_workflow=workflow_name )


def workflow_start( directory, paths, genome_run=None ):

  runs = Runs()

  # get config path
  config_path = setup_config_file( directory, genome_run )

  # get input file
  input_file = paths[ 'input' ] 

  # run workflow
  run_workflow( config_path, input_file, directory, genome_run )

  # return template( 'templates/workflow', wf=get_all_workflows(), current_workflow=workflow_name )


@route( '/new/:kind' )
@post( '/new/:kind' )
def new( kind ):

  errors = [ ]

  # Check if config is set
  config_dir = get_config_directory()
  config_types = get_types()
  database_config = None


  if kind == 'genome_run':

    if not os.path.isfile( config_dir + '/databases.json' ):
      errors.append( "Genome databases" )
    else:
      database_config = get_config( 'databases')
      for i in database_config:
        if not database_config[ i ] is None and not os.path.isfile( database_config[ i ] ):
          errors.append( str( database[ i ] ) +  ": File not found.")

    if request.method != 'POST' or len( errors ) > 0: 
      return template( 'templates/genome_run', errors=errors, config_error=1, is_workflow=1, database_config=database_config )


  if kind == 'genome_run':
    to_be_configured = ( 'omssa', 'xtandem', 'msgf', 'circos')
    tpl = 'templates/genome_run'
  else:
    to_be_configured = ( 'omssa', 'xtandem', 'msgf' )
    tpl = 'templates/new'

  if os.path.isfile( config_dir + "/fdr.json" ):
    config_not_set = 0
    for _t in to_be_configured:
      f = os.path.isfile( config_dir + "/" + _t + ".json" )

      if not f:
        config_not_set += 1
        errors.append( _t )

      if config_not_set > 0:
        return template( tpl , errors=errors , config_error = 1, is_workflow=True )
  else:
    errors.append( "fdr" )
    return template( tpl, errors=errors , config_error = 1, is_workflow=True )


  if request.method == 'POST':
    params = request.params

    print params

    if True:

      # generate a unique directory
      _d = name = str( uuid.uuid1() )

      # create a directory within workflow
      _directory = create_workflow( _d ) 
      paths = { }

      for _file_type in [ 'input', 'database' ]:

        # no database entry for genome_run
        if kind == 'genome_run'  and _file_type == 'database':
          continue

        _file = None

        # no uploaded file and path set
        if not request.files.get( _file_type + '_file', None ) and params[ _file_type ]:
          _file = os.path.abspath( params[ _file_type ] )

          if not os.path.isfile( _file ):
            errors.append( "The " + _file_type + " file does not exist" )

          dest = os.path.join( get_path_within_workflow( name, _file_type ), os.path.basename( _file ) ) 
          shutil.copyfile( _file, dest )
          paths[ _file_type ] = dest 

        else:

          _i = request.files.get(  _file_type + '_file', None )

          if _i is not None:
            # if not _i.filename.endswith( ".mgf" ):
            #  errors.append( "Appears to be invalid input file, must be a valid mgf file" )
            _save_as = os.path.join( get_path_within_workflow( name, _file_type ), _i.filename )

            # save _file
            save_file( _save_as, _i.file )
            paths[ _file_type ] = _save_as

          else:
            errors.append( "Invalid or No %s file given" % ( _file_type ) )

      print errors
    
      if len( errors ) > 0:
        shutil.rmtree( _directory )
        return template( 'templates/new', types=get_types(), errors=errors, config_error = 0 )
      else:
        print "STARTING WORKFLOWS"

        if kind == 'genome_run':
          workflow_start( _directory, paths, params[ 'database'] )
        else:
          workflow_start( _directory, paths, None )

        redirect( '/runs' )

  return template( 'templates/new', types=get_types(), errors=errors, config_error = 0 )


