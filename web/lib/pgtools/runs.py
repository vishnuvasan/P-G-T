import os
import os.path
import subprocess
import sys
import time
from pgtools.db import Runs
from paste import httpserver

def close_files_exhaustively(fd_min=3, fd_max=-1):
    import resource
    fd_top = resource.getrlimit(resource.RLIMIT_NOFILE)[1] - 1
    if fd_max == -1 or fd_max > fd_top:
        fd_max = 10000 
    for fd in xrange(fd_min, fd_max+1):
        try:
            os.close(fd)
        except:  
            pass


def write_pid( _dir, _pid=None ):
  _fh = open( os.path.join( _dir, 'run.pid' ), 'w' )

  if _pid is None:
    _pid = os.getpid()

  _fh.write( str( _pid ) )

  _fh.close()

def run_pgtool_command( command, pid_dir ):

  _pid_dir = os.path.abspath( pid_dir )

  # child process
  if os.fork() == 0:

    # close socket connections here and detach 
    # hopefully this should close all socket connections
    close_files_exhaustively()


    # change directories
    os.chdir( os.path.join( os.path.dirname( __file__ ), '..', '..' ) )

    # another child
    if os.fork() == 0:


      try:

        print command

        _process = subprocess.Popen(
          command,
          stdout=open( os.path.join( _pid_dir, 'stdout' ), 'w' ),
          stderr=open( os.path.join( _pid_dir, 'stderr' ), 'w' ),

        )
      except OSError as err:
        print "Can not start a process: "
        print command
        print err
        os._exit( 0 )

      try:
        write_pid( _pid_dir, _process.pid )
        _process.wait()
      except OSError as err:
        print "Can not write the PID file: "
        print err


      os._exit( 0 )

    else:
      os._exit( 0 )

  time.sleep( 1 )


def run_workflow( config_path, input_file, directory, genome_run=None ):
  print "** RUN WORKFLOW HERE **"
  os.environ[ 'PGTOOLS_CONFIG_PATH' ] = config_path

  cmd = ( 
    os.path.join( os.path.dirname( __file__ ), '..', '..', '..', 'src', 'pgtools' ), 
  )

  if genome_run is None:
    cmd = cmd + ( 'proteome_run', input_file )
  else:
    cmd = cmd + ( 'genome_run', '--' + str( genome_run), input_file )

  runs = Runs()

  run_pgtool_command( cmd, os.path.dirname( config_path ) )

  kind = 'proteome_run' if genome_run is None else 'genome_run'

  runs.create_run_entry(
    kind=kind,
    command=" ".join( cmd ),
    pid=get_pid_from_file( directory ),
    local_directory=directory,
    original_filename=input_file,
    output_filename='several',
    is_done=0
  )


def get_pid_from_file( directory_path ):
  return file( os.path.join( directory_path, 'run.pid') ).read()

def run_util_command( command=None, **kwargs ): 

  kind = command
  ifile, params, ld =  kwargs['saveas'], kwargs['params'], kwargs['local_directory']
  runs = Runs()

  ifile, ofile   = os.path.abspath( ifile ), os.path.abspath( 
    os.path.join( os.path.dirname( ifile ),  'output.' + os.path.basename( ifile ) ) 
  )

  # hack for decoy append
  if kind == 'decoy' and '-a' in params:
    ofile = ifile

  cmd = ( 
    os.path.join( os.path.dirname( __file__ ), '..', '..', '..', 'src', 'pgtools' ), 
    command 
  ) + tuple( params ) + ( ifile, ofile )

  run_pgtool_command( cmd, os.path.dirname( ifile ) )

  runs.create_run_entry(
    kind=kind,
    command=" ".join( cmd ),
    pid=get_pid_from_file( ld ),
    local_directory=ld,
    original_filename=ifile,
    output_filename=ofile,
    is_done=0
  )


