import os
import re
import sys

from bottle import  template, route,  get, post, request, response, redirect, BaseRequest

from pgtools.constants import *
from pgtools.config import *
from pgtools.config import _config_path, _save_to_path
from pgtools.workflows import *
from pgtools.util import *
from pgtools.runs import *


@route( '/configure/:kind' )
@post( '/configure/:kind' )
def configure( kind ):

  errors = [ ]
  _cfg = { }

  if request.method == 'GET':

    try: 
      _cfg[ kind ] = get_config( kind )
      print _cfg
    except:
      # default configuration for
      # search engines, specialized databases
      # and fdr
      if kind in 'fdr':
        _cfg[ kind ] = {
          'use_concatenated_decoy': True,
          'use_fdr_score': False,
          'fdr_cutoff': 5
        }
      elif kind in 'databases':
        _cfg[ kind ] = {
          'utr': None,
          'noncode': None,
          'pseudogene': None,
          'splice': None,
          '6frame': None
        }
      else:
        _cfg[ kind ] = {
          'enabled': '',
          'path': '',
          'options': get_default_options( kind ),
          'formatdb': ''
        }

  elif request.method == 'POST':
    params = request.params

    for _type in get_types() + [ 'fdr', 'databases' ]:

      if _type == kind:

        # there must be a way to automate this, no?
        if _type == 'omssa':
          cfg, errors = save_omssa()

        if _type == 'databases':
          cfg, errors = save_databases()

        if _type == 'xtandem':
          cfg, errors = save_xtandem()

        if _type == 'msgf':
          cfg, errors = save_msgf()

        if _type == 'fdr':
          cfg, errors = save_fdr()

        if _type == 'annotate':
          cfg, errors = save_annotate()

        if _type == 'circos':
          cfg, errors = save_circos()

        if _type == 'convert':
          cfg, errors = save_convert()

        if _type == 'circos':
          cfg, errors = save_circos()

        if len( errors ) == 0:

          if _type in [ 'omssa', 'xtandem', 'msgf' ]:

            if params.get( _type + '_enabled', 'off' ) in 'on': 
              cfg['enabled'] = 'checked'
            else:
              cfg['enabled'] = 'unchecked'

            # save files now
            if os.path.exists( _config_path( _type + '.json' ) ):
              os.system( 'rm ' + _config_path( _type + '.json ') )

            save_config( _type, cfg )



        print _cfg
        _cfg[ kind ] = cfg 

  print errors
  return template( 'templates/configure/' + kind, kind=kind, config=_cfg, types=get_types(), errors=errors, is_config=True )

