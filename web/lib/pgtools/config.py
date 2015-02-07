import os
import os.path
import uuid
import json
import subprocess
import re

from pgtools.constants import *

from bottle import run, request, response

def get_all_directories_within( path ):
  return map( lambda x: os.path.abspath( x ), os.listdir( path ) )

def get_data_directory():
  return os.path.join( ROOT_PATH, 'data'  )

def get_path_within_data_directory( path ):

  if not path:
    raise "No Path Given"

  _dir = os.path.join( get_data_directory(), path )

  if not os.path.isdir( _dir ):
    os.mkdir( _dir )

  return _dir

def get_config_directory():
  return get_path_within_data_directory( 'config' )



def _config_path( _file=None ):
  if _file is None:
    raise "No file given"
  else:
    return os.path.join( get_config_directory(), _file )


def _save_to_path( _file=None, data=None ):
  if not _file is None and not data is None:
    _fh = open( _file, 'w' )
    _fh.write( json.dumps( data ) )
    _fh.close()
  else:
    raise "No file given, or no data given"


def _read_from_path( _file=None ):
  if not _file is None and os.path.isfile( _file ):
    _fh = open( _file, 'r' )
    return json.load( _fh )
  else:
    raise "No file given, or the file does not exist"


def get_types():
  return [ 'omssa', 'xtandem', 'msgf', 'fdr', 'convert', 'annotate', 'circos', 'databases' ]


def get_config( _type="omssa" ):
  if _type in get_types():
    return _read_from_path( _config_path( _type + '.json' ) )
  else:
    raise "Invalid Type: " + _type


def save_config( _type='omssa', data=None ):
  if _type in get_types() + [ 'fdr', 'databases']:
    _save_to_path( _config_path( _type + '.json' ), data )
  else:
    raise "Invalid Type: " + _type


def get_default_options( _type='omssa' ):
  if _type == 'omssa':
    return "-e 10 -to 0.8 -te 2 -tom 0 -tem 0 -w"
  elif _type == 'xtandem':
    return ""
  elif _type == "msgf":
    return "-t 20ppm -ti -1,2 -ntt 2 -tda 1 "

def get_fdr_config():
  pass


def get_all_configs():
  config = { }

  for i in get_types():
    try:
      config[ i ] = get_config( i )
    except:
      config[ i ] = { 'path': None, 'options': None }


  try:
    config[ 'fdr' ] = get_config[ 'fdr' ]
  except:
    config[ 'fdr' ] = None


  return config


def check_exec_file ( _cmd = None ):
  if _cmd:
    p = subprocess.Popen( _cmd , stdout=subprocess.PIPE, shell=True )
    (output, err) = p.communicate()
    return output
  else:
    raise "No command given.."

def save_databases():

  params = request.params

  print params

  _config = {
    'utr': None,
    'noncode': None,
    'pseudogene': None,
    'splice': None,
    '6frame': None
  }

  errors = [ ]

  for i in _config.keys():
    path = params[ i ]
    if len( path ) > 0:
      if os.path.isfile( path ):
        _config[ i ] = path
      else:
        errors.append( path + " does not exist")

  print _config
  print errors

  if not len( errors ):
    save_config( 'databases', _config )

  return _config, errors


def save_omssa():
  params = request.params
  cfg = get_default_config()
  errors = [ ]
  path = params[ 'omssa_path' ]
  formatdb = params[ 'omssa_formatdb']

  if not os.path.isfile( path  ):
    errors.append( path + ' path does not exist' )

  # valid omssa?
  output = check_exec_file( path + " -version" )
  valid_type = re.search( "omssacl" , output )

  if not valid_type:
    errors.append( "Invalid OMSSA executable")
  else:
    cfg[ 'path' ] = path

  if not formatdb:
    errors.append( "No formatdb path given")
  else:
    cfg[ 'formatdb' ] = params[ 'omssa_formatdb']

  cfg[ 'options' ] = params[ 'omssa_options' ]

  print cfg
  print errors

  return cfg, errors

def save_xtandem():
  params = request.params
  cfg = get_default_config()
  errors = [ ]
  path = params.get( 'xtandem_path', None ) 

  if path is not None:
    if not os.path.isfile( path  ):
      errors.append( path + ' path does not exist' )

    # valid xtandem?
    output = check_exec_file( path + " foo" )
    valid_type = re.search( "TANDEM" , output )

    if not valid_type:
      errors.append( "Invalid xtandem executable")
    else:
      cfg[ 'path' ] = path
      cfg[ 'enabled' ] = 'checked'

    cfg[ 'options' ] = params.get( 'xtandem_options', None )
  else:
    errors.append( "No Path Given" )

  return cfg, errors


def save_msgf():
  params = request.params
  cfg = get_default_config()
  errors = [ ]
  path = params.get( 'msgf_path', None )

  if path is not None:
    if not os.path.isfile( path  ):
      errors.append( path + ' path does not exist' )

    # valid msgf?
    output = check_exec_file( "java -jar " + path )
    valid_type = re.search( "MS-GF" , output )

    if not valid_type:
      errors.append( "Invalid msgf executable")
    else:
      cfg[ 'path' ] = path


    cfg[ 'options' ] = params[ 'msgf_options' ]
  else:
    errors.append( "Invalid MSGF+ executable")

  return cfg, errors


def save_fdr():
  params = request.params
  errors = [ ]

  # Save FDR config
  _config = {
    'use_concatenated_decoy': True,
    'use_fdr_score': False,
    'fdr_cutoff': 5
  }

  if params.get( 'use_concatenated_decoy', None ) == 'on':
    _config[ 'use_concatenated_decoy'] = True

  if params[ 'fdr_cutoff' ]:
    _config['fdr_cutoff'] = params.get( 'fdr_cutoff', 5 )


  save_config( 'fdr', _config )

  print _config

  return _config, errors


def _save_just_path( kind, key, param ):
  params = request.params
  errors = [ ]

  # Save FDR config
  _config = {
    key: False 
  }

  if params.get( param, None ):
    _config[ key ] = params.get( param ) 

  save_config( kind, _config )

  return _config, errors


def save_circos():
  return _save_just_path( 'circos', 'command', 'circos_path' )

def save_convert():
  return _save_just_path( 'convert', 'command', 'convert_path' )


def save_annotate():
  pass


def get_default_config():
  return {
      'enabled': '',
      'path': '',
      'options': ''
  }

