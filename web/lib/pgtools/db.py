import sys
import os
import os.path
import sqlite3
import shutil
from datetime import datetime

from pgtools.constants import *
from pgtools.config import *

class Runs( object ):

  db_path = os.path.join( ROOT_PATH, 'data', 'runs.db' )


  def __init__( self ):

    self.connection = sqlite3.connect( Runs.db_path )

    # if we are not already installed
    self.install()

  def commit( self ):
    self.connection.commit()

  def install( self ):
    if not self.is_installed():
      cursor = self.cursor()

      for query in self.ddl():
        cursor.execute( query )

      for query in self.inserts():
        cursor.execute( query )
        self.commit()

  def cursor( self ):
    return self.connection.cursor()

  def query( self, query ):
    cursor = self.cursor()
    cursor.execute( query )
    return cursor


  def remove( self, run_id ):

    row = self.row_to_dict( 
      self.query( "SELECT * FROM runs WHERE id=%d" % ( int( run_id ) ) ).fetchone()
    )

    try:
      shutil.rmtree( row[ 'local_directory'] )
    except:
      pass

    self.query( "DELETE FROM runs WHERE id=%d" % ( int( run_id ) ) )
    self.commit()


    return True

  def find( self, view_id ):
    cursor = self.query( "SELECT * FROM runs WHERE id=%d" % ( int( view_id ) ) )
    row = self.row_to_dict( cursor.fetchone() )

    return row


  def is_installed( self ):
    try:
      cursor = self.query( 'SELECT installed FROM installed' )
      return ( cursor.fetchone() )[0] == 'done'
    except:
      return False

  def create_run_entry( self, **kwargs ):

    query = '''
      INSERT INTO runs
      ( type, command, pid, local_directory, original_filename, output_filename, is_done, config_path, created_at )
      VALUES
      ( ?, ?, ?, ?, ?, ?, ?, ?, ? )
    '''

    now = datetime.now()

    cursor = self.cursor()
    cursor.execute( query,
      ( 
        kwargs[ 'kind'], kwargs[ 'command'], kwargs['pid'], kwargs[ 'local_directory'], 
        kwargs[ 'original_filename'], kwargs['output_filename'], 0, '', now.strftime( '%Y-%m-%d %H:%M:%S')
      )
    )

    self.commit()



  def get_all_runs( self ):
    cursor = self.cursor()
    cursor.execute( 'SELECT * FROM runs')
    results = [ ]

    for row in cursor:
      if row:
        results.append( self.row_to_dict( row ) )

    return results;

  def row_to_dict( self, row ):
    return {
      'id': row[ 0 ],
      'kind': row[ 1 ],
      'command': row[ 2 ],
      'pid': row[ 3 ],
      'local_directory': row[ 4 ],
      'input_filename': row[ 5 ],
      'output_filename': row[ 6 ],
      'created_at': row[9]
    }


  def ddl( self ):
    return [
        '''
          CREATE TABLE runs (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            type VARCHAR( 50 ),
            command VARCHAR( 500 ),
            pid int,
            local_directory TEXT,
            original_filename TEXT,
            output_filename TEXT,
            is_done int,
            config_path TEXT,
            created_at DATETIME
          )
        ''',

        '''
          CREATE TABLE installed (
            installed VARCHAR( 50 )
          )
        '''
    ]

  def inserts( self ):
    return [
      '''
        INSERT INTO installed ( installed ) VALUES ( 'done' )
      '''
    ]

