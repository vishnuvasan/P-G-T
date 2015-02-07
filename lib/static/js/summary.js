$( document ).ready( function() {

  $( '.nav-sidebar li a').click( function( e ) {
    e.preventDefault();
    e.stopPropagation();

    var t = $( this ),
        p = t.parent( 'li' ),
        item = p.attr( 'data-item' );

    $( '.pane-item' ).removeClass( 'show' ).addClass( 'hide' )
    $( '.pane-item.' + item ).removeClass( 'hide' ).addClass( 'show' )

    p.parent( 'ul' ).find( 'li' ).removeClass( 'active' )
    p.addClass( 'active' );


  });

} );
