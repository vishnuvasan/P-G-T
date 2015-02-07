import config
import os
import os.path
import re
import json


def get_workflow_directory():
  return config.get_path_within_data_directory( 'workflows' )

def get_all_workflows():
  return config.get_all_directories_within( get_workflow_directory() )

def create_workflow( name ):

  if not name:
    raise "No name given, can not create a workflow"

  _dir = os.path.join( get_workflow_directory(), name ) 

  if os.path.isdir( _dir ):
    raise Exception( "Workflow already exists, can not overwrite: " + _dir )

  os.mkdir( _dir )

  return _dir


def get_input_file( name ):
  _path = get_workflow( name )
  _input = [ os.path.abspath( os.path.join( _path, 'input', i ) ) for i in os.listdir( os.path.join( _path, 'input' ) ) if i.endswith( '.mgf' ) ]

  return _input[ 0 ]


def setup_config_file( directory, genome_run=None ):

  _path = directory 

  if genome_run is None:
    _database = [ 
        os.path.abspath( os.path.join( directory, 'database',  i ) ) 
          for i in os.listdir( os.path.join( directory, 'database' ) ) 
            if i.endswith( '.fa' ) or i.endswith( '.fasta' ) 
    ]
  else:
    _database = None

  _defaults = [ ]
  _algorithms = [ ]

  # msearch setup
  for i in ( 'OMSSA', 'XTandem', 'MSGF' ):

    _config = config.get_config( i.lower() )

    if _config is not None:

      _name = i.lower()

      if _config[ 'enabled' ] == 'checked':
        _defaults.append( _name ) 

      _c = {
        'name': _name,  
        'command': _config[ 'path'],
        'options': _config[ 'options' ],
        'class': i
      } 

      if _name == 'omssa':
        _c[ 'formatdb' ] = _config[ 'formatdb' ]

      _algorithms.append( _c )



  _fdr_config     = config.get_config( 'fdr' )

  try:
    _circos_config  = config.get_config( 'circos' )
  except: 
    _circos_config = None

  try: 
    _convert_config = config.get_config( 'convert' )
  except:
    _convert_config = None

  try:
    _databases_config = config.get_config( 'databases' )
  except:
    _databases_config = None

  

  _scratch_directory = os.path.abspath( os.path.join( _path, 'scratch' ) )

  if not os.path.isdir( _scratch_directory ):
    os.mkdir( _scratch_directory )

  _config = {

    'phase2_databases': { } if _databases_config is None else _databases_config,

    'scratch_directory': _scratch_directory,

    "annotate": {
      "url": "http://caffainerush.delta18.com",
      "database": "annotation.sqlite"
    },

    'msearch': {
      'defaults': _defaults,
      'cutoff': _fdr_config[ 'fdr_cutoff' ],
      'database': _database[ 0 ] if not _database is None else None,

      'decoy': {
        'prepare': True,
        'concat': _fdr_config[ 'use_concatenated_decoy' ]
      },

      'use_fdr_score': 0,

      'algorithms': _algorithms
    },

    'convert': {
      'command': _convert_config.get( 'command', None ) if _convert_config else None
    }

  }

  print _config

  _config_path = os.path.abspath( os.path.join( _path, 'config.json' ) )

  _fh = open( _config_path, 'w' )
  _fh.write( json.dumps( _config ) )
  _fh.close()

  return _config_path


def get_workflow( name ):
  return os.path.join( get_workflow_directory(), name ) 


def get_path_within_workflow( name, _type='input' ):
  _dir = os.path.join( get_workflow( name ), _type )

  if os.path.exists( _dir ):
    pass
  else:
    os.mkdir( _dir )

  return _dir


def save_file( name, _file ):
  fh = open( name, 'wb' )

  while True:
    data = _file.read( 1024 * 5 )
    if not data:
      break
    else:
      fh.write( data )

  fh.close()
