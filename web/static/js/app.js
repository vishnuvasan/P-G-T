$(function () {
try {
	$('.menu .accordion-heading').click(function(){
		$('.menu .accordion-heading').children('.accordion-toggle').removeClass('selected-black')
		$(this).children('.accordion-toggle').addClass('selected-black');
	});
	$('.menu-inner a').click(function(){
		$('.menu-inner a').children('li').removeClass('selected-yellow');
		$(this).children('li').addClass('selected-yellow');
	});


//AUTOCOMPLETE
$('.path-typeahead').typeahead({
  source: function(query, process) {

    return $.getJSON(
    '/path.json',
    { query: query },
    function (data) {
            return process(data);
    });
  }
});


//Slider

  $( '.value-slider').each( function( index, el ) {
    var $el = $( el );
    $el.slider( {
      min: parseInt( $el.attr( 'data-min') ) || 0,
      max: parseInt( $el.attr( 'data-max') ) || 100,
      value: parseInt( $el.attr( 'data-value') ) || 50,
      slide: function( event, ui ) {
        var func = $el.attr( 'data-callback');
        if( func in window && typeof window[ func ] == 'function' ) {
          window[ func ]( ui.value );
        }
      }
    })
  });


    $( "#slider2" ).slider({
      range: true,
      min: 0,
      max: 500,
      values: [ 75, 300 ]
    });

//Footer

	$('.footer-down').click(function(){
		var currHeight=parseInt($(this).parent().css('height'));
		if (currHeight >50){
			$(this).parent().animate({'height':'10px'});
			$(this).siblings('.footer-logos').animate({'opacity':0});
			$(this).attr('src','img/up.png');
		} else {
			$(this).parent().animate({'height':'105px'});
			$(this).siblings('.footer-logos').animate({'opacity':1});
			$(this).attr('src','img/down.png');
		}
	})



} catch( e ) { }
});
