import os

ROOT_PATH     = os.path.abspath( 
  os.path.join( os.path.dirname( __file__ ), '..', '..' )
)

STATIC_PATH   = os.path.join( ROOT_PATH, 'static' )

TEMPLATE_PATH = os.path.join( ROOT_PATH, 'templates' )

ANNOTATE_URL  = 'http://caffainerush.delta18.com/annotation.sqlite'
