$(function () {
	$('.menu .accordion-heading').click(function(){
		$('.menu .accordion-heading').children('.accordion-toggle').removeClass('selected-black')
		$(this).children('.accordion-toggle').addClass('selected-black');
	});
	$('.menu-inner a').click(function(){
		$('.menu-inner a').children('li').removeClass('selected-yellow');
		$(this).children('li').addClass('selected-yellow');
	});


//AUTOCOMPLETE
		$('#typeahead').typeahead({
			source: function (query, process) {
				return $.getJSON(
				'http://localhost/hashing/1.php',
				{ query: query },
				function (data) {
					return process(data);
				});
			}
		});
		
//Slider

	$('#slider1').slider({
		range: "min"
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



});