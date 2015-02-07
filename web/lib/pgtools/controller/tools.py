import os
import sys
import bottle
from bottle import  route,  get, post, request, response, redirect, BaseRequest, HTTPResponse

from pgtools.constants import *
from pgtools.config import *
from pgtools.workflows import *
from pgtools.util import *
from pgtools.runs import *

def template( _tpl, *args, **kwargs ):
  kwargs.update( { 'is_tool': True } )
  return bottle.template( _tpl, **kwargs)

def _do( kind ):
  if request.method == 'POST':
    try:
      run_util( request, kind )
      redirect( '/runs' )
    except HTTPResponse:
      raise

    except:
      print sys.exc_info()
      errors = [ "Make sure you upload correct fasta file" ]
      return template( 'templates/' + kind, errors=errors )
  else:
    return template( 'templates/' + kind, errors=[] )


@route( '/decoy' )
@post( '/decoy' )
def decoy():
  return _do( 'decoy' )


@route( '/translate' )
@post( '/translate' )
def translate():
  return _do( 'translate' )


@route( '/annotate')
@post( '/annotate')
def annotate():
  return _do( 'annotate' )


@route( '/convert')
@post( '/convert')
def convert():

  if request.method == 'GET':
    is_configured = False

    try:
      is_configured = get_config( 'convert') is not None
    except:
      pass

    return template( 'templates/convert', errors=[], is_configured=is_configured ) 

  else:
    return _do( 'convert' )


