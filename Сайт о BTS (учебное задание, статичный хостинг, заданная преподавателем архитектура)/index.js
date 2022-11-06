const pictures = ['1.gif', '1.jpg', '2.gif', '3.gif', '4.gif', '4.jpg', '5.jpg', 'all 1.jpg', 'all 2.jpg', 'beer.jpg', 'upside down.jpg']

const Headers = new Map()
Headers.set("begin.html", "All hail BTS!")
Headers.set("gallery.html", "Галерея")
Headers.set("imageview.html", "Просмотр медиа")
Headers.set("members.html", "Анкеты участников")
Headers.set("albums.html", "Альбомы")

let lastScroll = 0
let lastPage = null
let ignoreBack = false

$(document).ready(function(){
	$(window).on("popstate", goBackButton);
	$("#menu li").on("click", change)[0].click()
	$('#back').on("click", goBackArrow)
});

function scrollMain(amount) {
	$('#main').scrollTop(amount)
	if ($('#main').scrollTop() != amount) {
		setTimeout(scrollMain, 10, amount)
	} else {
		lastScroll = 0
	}
}

function canGoBack() {
	return $("#back").is(':visible') && lastPage
}

function goBackArrow() {
	history.back()
}

function goBackButton() {
	if(canGoBack() && !ignoreBack) {
		change(lastPage, true)
		scrollMain(lastScroll)
	}
	ignoreBack = false
	$("#back").hide()
}

function change(element, fromBack) {
	element.target = $(element.target).closest('[data-file]')
	// console.log(element.target)
	const dataFile = $(element.target).data("file")
	if(dataFile){
		$('.sign').each(function() {
			$(this).html("")
		})
		$.get(dataFile, function(data){
			if (dataFile == "imageview.html") {
				lastScroll = $('#main').scrollTop()
				$("#back").show()
				history.pushState( "nohb", null, "" );
			} else {
				if (canGoBack() && !fromBack) {
					ignoreBack = true
					history.back()
				} else {
					scrollMain(0)
				}
				$(element.target).find(".sign").html("&#x221a ")
				lastPage = element
			}
			$("#head h1").html(Headers.get(dataFile))
			$("#main").html(data)
			if(dataFile == "gallery.html"){
				pictures.forEach(function(picName) {
					let thumbTemplate=
					`<div class="thumb" data-file="imageview.html">
						<div class="thumbImg"><img src='img/gallery/${picName}'></div>
						<div class="thumbName"><span>${picName}</span></div>
					</div>`
					$("#main").append(thumbTemplate)
				})
			} else if (dataFile == "imageview.html"){
				let filename = $(element.target).find("[src]").attr("src") || $(element.target).attr("src")
				$("#imageview img").attr("src", filename)
				$("#imageview p").html('<b>' + filename.substring(filename.lastIndexOf('/') + 1) + '</b>')
			} else if (dataFile == "albums.html") {
				$('.player .tracks').on('change', function() {
					changeTrack(this, $(this).val())
				})
			}
			$('[data-file]').addClass('clickable').off('click').on("click", change)
		})
	} 
}

function changeTrack(playerSelector, sourceUrl) {
	let audio = playerSelector.nextElementSibling
	audio.pause()

	if (sourceUrl) {
		audio.src = sourceUrl
		audio.load()
		audio.play()
	}
}