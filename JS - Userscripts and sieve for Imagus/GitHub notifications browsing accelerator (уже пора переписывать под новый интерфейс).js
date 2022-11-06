// ==UserScript==
// @name        GitHub notifications browsing accelerator 
// @namespace   Violentmonkey Scripts
// @match       *://github.com/*
// @grant       none
// @version     2.2
// @author      Ranhum
// @description 1/22/2020, 7:19:35 PM
// ==/UserScript==

function simulate(element, eventName)
{
    var options = extend(defaultOptions, arguments[2] || {});
    var oEvent, eventType = null;

    for (var name in eventMatchers)
    {
        if (eventMatchers[name].test(eventName)) { eventType = name; break; }
    }

    if (!eventType)
        throw new SyntaxError('Only HTMLEvents and MouseEvents interfaces are supported');

    if (document.createEvent)
    {
        oEvent = document.createEvent(eventType);
        if (eventType == 'HTMLEvents')
        {
            oEvent.initEvent(eventName, options.bubbles, options.cancelable);
        }
        else
        {
            oEvent.initMouseEvent(eventName, options.bubbles, options.cancelable, document.defaultView,
            options.button, options.pointerX, options.pointerY, options.pointerX, options.pointerY,
            options.ctrlKey, options.altKey, options.shiftKey, options.metaKey, options.button, element);
        }
        element.dispatchEvent(oEvent);
    }
    else
    {
        options.clientX = options.pointerX;
        options.clientY = options.pointerY;
        var evt = document.createEventObject();
        oEvent = extend(evt, options);
        element.fireEvent('on' + eventName, oEvent);
    }
    return element;
}

function extend(destination, source) {
    for (var property in source)
      destination[property] = source[property];
    return destination;
}

var eventMatchers = {
    'HTMLEvents': /^(?:load|unload|abort|error|select|change|submit|reset|focus|blur|resize|scroll)$/,
    'MouseEvents': /^(?:click|dblclick|mouse(?:down|up|over|move|out))$/
}
var defaultOptions = {
    pointerX: 0,
    pointerY: 0,
    button: 0,
    ctrlKey: false,
    altKey: false,
    shiftKey: false,
    metaKey: false,
    bubbles: true,
    cancelable: true
}

/*
function simulateKey(keyCode, type, modifiers) {
	var evtName = (typeof(type) === "string") ? "key" + type : "keydown";	
	var modifier = (typeof(modifiers) === "object") ? modifier : {};

	var event = document.createEvent("HTMLEvents");
	event.initEvent(evtName, true, false);
	event.keyCode = keyCode;
	
	for (var i in modifiers) {
		event[i] = modifiers[i];
	}
	document.dispatchEvent(event);
}
*/

let $ = document.querySelector.bind(document);
let click = sel => simulate($(sel), "click");
const isNList = window.location.toString().includes("https://github.com/notifications");
const isRoot = window.location == "https://github.com/notifications";
let curCount = 0;

function getCount(mode) {
  const extract = node => node? node.textContent : 0;
  switch (mode) {
    case 1:
      return $(".js-notification-inboxes .count").textContent;
    case 2:
      return $(".js-notifications-list-paginator-counts").lastChild.textContent.split(/\s/)[2];
    case 3:
      return extract($(".js-notification-sidebar-repositories a.selected .count"));
    case 4:
      return extract($(".js-notification-sidebar-repositories a:not(.selected) .count"));
    default:
      if (isNList && !isRoot)
        return getCount(2);
      else if (isNList)
        return getCount(1);
  }
}

async function navigateToNextUnread() {
  if (isRoot)
    if ($(".js-notifications-group-view-all"))
      click(".js-notification-sidebar-repositories a:not(.selected)");
    else {
      const totalCount = $("img.py-2")? -1 : getCount(1);
      while (totalCount == getCount(1))
        await new Promise(r => setTimeout(r, 10));
      window.location.reload();
    }
  else
    if (curCount <= 25) {
      while (!$(".blankslate-icon"))
        await new Promise(r => setTimeout(r, 10));
      click((((getCount(1) <= 25) || getCount(4) == 1))?
              ".js-notification-inboxes a" :
              ".js-notification-sidebar-repositories a:not(.selected)");
    } else {
      while (curCount == getCount(2))
        await new Promise(r => setTimeout(r, 100));
      curCount = getCount(2);
    }
}

async function markAsReadAndProceed() {
  if (!isNList) {
    if ($(".notification-action-mark-archived .btn[data-hotkey]"))
      click(".notification-action-mark-archived .btn[data-hotkey]");
    else
      click(".notification-indicator");
  } else if ($(".notification-list-item-link")) {
    click(".js-notifications-mark-all-prompt");
    while ($(".js-notifications-mark-selected-actions").hidden)
      await new Promise(r => setTimeout(r, 10));
    click(".js-notification-bulk-action .btn");
    navigateToNextUnread();
  } else if (isRoot)
    navigateToNextUnread();
}

if (isNList && !isRoot && !$(".notification-list-item-link") || isRoot && $(".js-notifications-group-view-all"))
  navigateToNextUnread();
else {
  if (isNList) curCount = getCount();
  document.addEventListener('keyup', event => {
    if (event.code === "KeyN" && !['INPUT','TEXTAREA'].includes(event.target.tagName)) markAsReadAndProceed();
    console.log(event);
  });
}
