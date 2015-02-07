$( document ).ready( function( ) {

  $.each( [ 'step', 'new-workflow' ], function( i, v ) {
    if( $( '#' + v ).length ) {
      $( '#' + v ).stepy();
    }
  } );

  $( '#tcontrol' ).click( function( e ) {
    var t = $( this );


    if( t.is( ':checked' ) ) {
      $( 'input[name="translate"]' ).each( function( index, el) {
        el.checked = true
      });
    }

    else {
      $( 'input[name="translate"]' ).each( function( index, el ) {
        el.checked=false;
      } );
    }

  } );


} );

// Global
function fdr_cutoff( value ) {
  $( '#fdr-cutoff-display').html( value + '%' );
  $( '#fdr_cutoff').val( value );
}

console.log( "HOYO");
$( document ).ready( function() {

  console.log( "HOYO");
  
  if( $( '.arrows-and-boxes').length ) {

    console.log( "YO" );

    function update_status() {
      var items = { 
        merge: / pepmerge /, 
        'omssa': /omssacl /, 
        'xtandem': /tandem(\.exe)? /, 
        'msgf': /java /, 
        'group': / group /, 
        'fdr':/ fdr /, 
        'annotate': / annotate /,
        'done': / summary /,
      };

      // Return the last item
      var get_item_key = function( obj ) {
        var key;

        for( i in items ) {
          if( obj.command.match( items[ i ] ) ) {
            key = i;
          }
        }

        return key;
      };


      $.getJSON( '/run_status/' + $.view_id + '.json', function( run_status ) {
        var done = { };
        for( var key in run_status ) {

          if( run_status.hasOwnProperty( key ) && ! done[ key ] ) { 

            var item_key = get_item_key( run_status[ key ] );


            if( item_key ) {

              var exit_status = run_status[ key ][ 'exit_status' ]; 

              //console.log( item_key );
              //console.log( exit_status );


              if( exit_status === null ) {
                $( '.' + item_key + '-node' ).
                  removeClass( 'finished-node' ).
                  addClass( 'running-node' );
              }

              else if( exit_status === 0 ) {
                console.log( item_key );
                $( '.' + item_key + '-node' ).
                  removeClass( 'running-node' ).
                  addClass( 'finished-node' );
              }

              else {
                $( '.' + item_key + '-node' ).
                  removeClass( 'runing-node' ).
                  addClass( 'error-node' );
              }

            }

          }
        }
      } );

      setTimeout( update_status, 2000 );

    }

    update_status();
  }

});

