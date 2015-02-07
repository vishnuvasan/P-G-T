import sys
import os
import os.path
import stat
import shutil
import pprint
import re
import json
import re

sys.path.insert( 0, 'lib' )

from bottle import run, template, route, static_file, get, post, request, response, redirect, BaseRequest, PasteServer

from pgtools.constants import *

from pgtools.config import *
from pgtools.workflows import *
from pgtools.util import *
from pgtools.runs import *
from pgtools.db import Runs

from pgtools.controller.configuration import *
from pgtools.controller.workflows import *
from pgtools.controller.tools import *
from pgtools.controller.view import *


@route( '/static/:kind/:filename' )
def serve_static_file( kind='js', filename=None ):
  if filename is not None:
    return static_file( filename, root=os.path.join( STATIC_PATH, kind ) )

@route( '/util/:run_type/:file_name/:what' )
def serve_util_files( run_type, file_name, what ):
  _util = os.path.abspath( get_util( file_name, run_type ) )
  return static_file( what, root=_util, download=True )


@route( '/' )
def index():
  return template( 'templates/index' )


@route( '/runs' )
def run_list():
  return template( 'templates/runs', items=get_all_runs(), original=None, transformed=None )

@route( '/run/:run_type/:file_name' )
def run_detail( run_type, file_name ):
  sample_original, sample_transformed = get_samples( run_type, file_name )

  return template( 'templates/runs', items=get_all_runs(), original=sample_original, transformed=sample_transformed, run_type=run_type, file_name=file_name )


@route( '/path.json' )
def path_json():
  query = request.params.get( 'query', None )
  dirname = os.path.dirname( query )
  results = [ ]

  if query is not None:
    results = map( 
      lambda y: y.replace( '//', '/' ),
      map( lambda x: dirname + '/' + x,  os.listdir( dirname ) ) 
    )

  return json.dumps( results ) 

def get_proteome_run_status( view ):
  directory = view[ 'local_directory' ]
  run_directory = os.path.join( directory, 'scratch', os.listdir( os.path.join( directory, 'scratch') )[ 0 ] )
  return file( os.path.join( run_directory, 'current_status.json') ).read()

def get_genome_run_status( view ):
  db_directory = get_db_directory( view )
  return file( os.path.join( db_directory, 'current_status.json' ) ).read()

@route( '/run_status/:run_id.json')
def run_status( run_id ):
  view = Runs().find( run_id )

  print view
  if view[ 'kind' ] == 'proteome_run':
    return get_proteome_run_status( view )
  elif view[ 'kind' ] == 'genome_run':
    return get_genome_run_status( view )




def write_headers_for_file( filename ):
  print filename
  if filename.strip().endswith( 'html'):
    response.headers[ 'Content-Type'] = 'text/html'
  elif filename.strip().endswith( 'css' ):
    response.headers[ 'Content-Type'] = 'text/css'
  elif re.match( r'\.png$', filename ):
    response.headers[ 'Content-Type'] = 'image/png'
  else:
    response.headers[ 'Content-Type'] = 'text/plain'


@route( '/show_static')
def show_static():
  filename = request.params.get( 'file' )
  if os.path.isfile( filename ):
    write_headers_for_file( filename )
    data = file( filename ).read()
    ( new_data, number ) = re.subn( r'file:\/\/', '/show_static?file=', data )
    return new_data
  else:
    return template( 'nofile', filename=filename, )

@route( '/remove/:run_id' )
def remove( run_id ):
  Runs().remove( run_id )
  redirect( '/runs' )

# run server
if __name__ == '__main__':
  run( host='0.0.0.0', port=3000, server=PasteServer )
