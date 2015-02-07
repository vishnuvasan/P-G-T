import config
import os
import os.path
import re
import uuid
from pgtools.db import Runs
from pgtools.workflows import *
from pgtools.runs import *
from pgtools.config import *
from pgtools.db import Runs



def get_util_directory():
  return config.get_path_within_data_directory( 'utils' )

def get_all_utils():
  return config.get_all_directories_within( get_util_directory() )

def normalize_filename( name ):
  not_allowed_name = re.compile( r'[^a-z0-9_\.]+', re.IGNORECASE )
  return re.sub( not_allowed_name, '_', name, 120000 )

def create_util_directory( name ):
  if not name:
    raise "No name given, can not create a util directory"
  
  _dir = os.path.join( get_util_directory(), str( uuid.uuid1() ) )

  if os.path.isdir( _dir ):
    os.unlink( _dir )

  os.mkdir( _dir )

  return _dir

def _get_util_directory( name ):

  utils = ( filter( lambda x: name in x, os.listdir( get_util_directory() ) ) )

  if len( utils ) > 0:
    return os.path.join( get_util_directory(), utils[ 0 ] )
  else:
    return None


def has_util( name, _type='decoy' ):
  return _get_util_directory( _type + '_' + get_util_directory() )

def create_util( name, _type='decoy' ):
  return create_util_directory( _type + '_' + name )

def get_util( name, _type='decoy' ):
  return _get_util_directory( _type + '_' + name )

def get_all_runs():
  return Runs().get_all_runs()


def _get_sample( file_name, read ):
  fh = open( file_name, 'r' )
  data = fh.read( read )
  fh.close()

  return data


def get_samples( run_type, file_name ):
  _util_directory = os.path.abspath( get_util( file_name, run_type ) )

  _original_file = os.path.join( _util_directory, file_name )
  _transformed_file = os.path.join( _util_directory, 'output.' + file_name )

  _transformed_sample = None

  if os.path.isfile( _transformed_file ):
    _transformed_sample = _get_sample( _transformed_file, 1024 )

  return ( _get_sample( _original_file, 1024 ), _transformed_sample )



def run_util( request, _type='decoy' ):

  runs = Runs()
  if request.method == 'POST':

    # get file name
    _file = request.files.get( 'db_file', None )

    _normalized = normalize_filename( _file.filename )

    errors = [ ]

    if _file is None:
      raise "Invalid file"



    if True:

      _u = create_util( _normalized, _type )

      _save_as = os.path.join( _u, _normalized )

      save_file( _save_as, _file.file )

      params = [ ]

      # run the util
      if _type == 'decoy':
        if request.params[ 'decoy_type' ] == 'random':
          params.append( '-r' )

        if int( request.params[ 'append' ] ) == 1:
          params.append( '-a' )

        run_util_command( 'decoy', params=params, saveas=_save_as, local_directory=_u  )

      elif _type == 'translate':

        print repr( request.params )

        if request.params.getall( 'translate' ):

          print request.params.getall( 'translate' )

          params.append( '-f' )
          params.append( ",".join( request.params.getall( 'translate' )  ) )

        run_util_command( 'translate', params=params, saveas=_save_as, local_directory=_u )

      elif _type == 'annotate':

        if request.params[ 'protein_id']:
          params.append( '--protein_id=%d' %  ( int( request.params[ 'protein_id' ] ) ) )
        else:
          params.append( '--protein_id=0' )

        if request.params[ 'file_type' ] in 'csv':
          params.append( '--csv' )
        else:
          params.append( '--tsv' )

        print params

        run_util_command( 'annotate', params=params, saveas=_save_as, local_directory=_u )

      elif _type == 'convert':

        print request.params

        if request.params[ 'file_type']:
          directory, filename = os.path.dirname( _save_as ), os.path.basename( _save_as )
          fname, suffix = os.path.splitext( filename )
          new_filename = fname + '.' + request.params[ 'file_type' ]

          params.append( '-out' )
          params.append( os.path.join( directory, new_filename ) )


        # get convert configuration
        try:
          convert_config = get_config( 'convert')
        except:
          convert_config = None

        print "CONVERT"
        print convert_config

        if convert_config is not None:

          cmd = ( convert_config[ 'command' ], ) + ( '-in', _save_as, ) + tuple( params ) 
          ld = os.path.dirname( _save_as )

          print cmd

          # run command
          run_pgtool_command( cmd, ld ) 

          # create run entry
          runs.create_run_entry(
            kind='convert',
            command=" ".join( cmd ),
            pid=get_pid_from_file( ld ),
            local_directory=ld,
            original_filename=_save_as,
            output_filename=os.path.join( directory, new_filename ),
            is_done=0
          )



        





