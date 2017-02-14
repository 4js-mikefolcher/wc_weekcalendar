//ChG: Some king of wrapper that links calendar.4gl and jquery.weekcalendar.js together

//var myEventList = {"options":{"timeslotsPerHour": 3},"events":',[{"id":1,"userId":1,"start":"2017-01-27 09:30:00","end":"2017-01-27 10:00:00","title":"Test data","eventdesc":"FF91 Project","eventparent":0}]};
var myEventList = {"options":{},"events":[]};

// Genero Webcomponent API
onICHostReady = function(version) {
  if( version != 1.0 ) {
    alert('Invalid API version');
  }

  // Called when data are coming from 4GL app
  gICAPI.onData = function(eventList) {
    //format and update calendar for each event coming from 4GL
    var eventObj = false;
    var optionObj = false;

    try{
      eventObj = JSON.parse(eventList);
      optionObj = eventObj.options;
      eventObj = eventObj.events;
    }catch (error) {
      eventObj = false;
    }

    if(eventObj) {
      myEventList.options = optionObj;
    }

    if(eventObj) {
      myEventList.events.splice(0,myEventList.length);
      for (var i = 0; i < eventObj.length; i++) {
        $("#calendar").weekCalendar("updateEvent",eventObj[i]);
        myEventList.events.push(eventObj[i]);
      }
    }
  }
};

function launchFunction( fctName ) {
      $('#calendar').weekCalendar(fctName);
};

function redraw(nbDays) {
      myEventList.options.daysToShow = nbDays;
      $('#calendar').weekCalendar('setDaysToShow',myEventList.options.daysToShow);
};

function setFglEvents() {
      return myEventList;
};

function setFglUsers( strJsonUsers ) {
    $('#calendar').weekCalendar({users: JSON.parse(strJsonUsers)});
};

function removeEvent( eventId ) {
    $('#calendar').weekCalendar('removeEvent',eventId);
};

function getStartHour() {
  var bhObj = $('#calendar').weekCalendar('option','businessHours');
  return(bhObj.start);
};

function getEndHour() {
  var bhObj = $('#calendar').weekCalendar('option','businessHours');
  return(bhObj.end);
};

// Once document is loaded
$(document).ready(function() {
  // Initial configuration for the calendar
  $('#calendar').weekCalendar({
    // default selected day
    date: 'today',
    // 0 = Sunday, 1 = Monday, 2 = Tuesday, ... , 6 = Saturday
    buttons: false,
    firstDayOfWeek:1,
    dateFormat: 'M d, Y',
    use24Hour: false,
    allowCalEventOverlap: true,
    overlapEventsSeparate: false,
    // Limit display to defined business hours
    businessHours: {start: 8, end: 19, limitDisplay: true},
    data:function(start, end, callback) {
			callback(setFglEvents());
    },

    // Multi Users
    showAsSeparateUsers: true,
    users: [],
    getUserId: function(userJson, index, calendar) {
          return userJson.userid;
    },
    getUserName: function(userJson, index, calendar) {
          return userJson.firstname+" "+userJson.lastname;
    },
    // set shortcuts on view
    switchDisplay: {'1 day': 1,'3 days': 3,'Work week': 5, 'Full week': 7},
    // Minimum of 15mins slots
    timeslotsPerHour: 4,
    timeslotHeight: 20,
    height: function() {
      return $(window).height() - $('h1').outerHeight() - $('.description').outerHeight();
    },
    // Event rendering (color, background, border)
    eventRender: function(calEvent, $event) {
      if (calEvent.end.getTime() < new Date().getTime()) {
        $event.css('backgroundColor', '#aaa');
        $event.find('.time').css({
          backgroundColor: '#999',
          border:'1px solid #888'
        });
      }
    },
    // Callback when new Event
    eventNew: function(calEvent) {
      gICAPI.SetFocus();
      gICAPI.SetData('{"id":"' + calEvent.id + '","userId":"' + calEvent.userId + '","start":"' + formatFglDateTime(calEvent.start) + '", "end":"' + formatFglDateTime(calEvent.end) + '", "title": "' + calEvent.title +'", "eventdesc": "'+ calEvent.eventdesc +'", "eventparent":"'+calEvent.eventparent+'"}');
      gICAPI.Action('new');
    },
    // Callback when update Event duration
    eventResize: function(calEvent) {
      gICAPI.SetFocus();
      gICAPI.SetData('{"id":"' + calEvent.id + '","userId":"' + calEvent.userId + '","start":"' + formatFglDateTime(calEvent.start) + '", "end":"' + formatFglDateTime(calEvent.end) + '", "title": "' + calEvent.title +'", "eventdesc": "'+ calEvent.eventdesc +'", "eventparent":"'+calEvent.eventparent+'"}');
      gICAPI.Action('move');
    },
    // Callback when moved Event
    eventDrop: function(calEvent) {
      gICAPI.SetFocus();
      gICAPI.SetData('{"id":"' + calEvent.id + '","userId":"' + calEvent.userId + '","start":"' + formatFglDateTime(calEvent.start) + '", "end":"' + formatFglDateTime(calEvent.end) + '", "title": "' + calEvent.title +'", "eventdesc": "'+ calEvent.eventdesc +'", "eventparent":"'+calEvent.eventparent+'"}');
      gICAPI.Action('move');
    },
    eventClick: function(calEvent, $event) {
      gICAPI.SetFocus();
      gICAPI.SetData('{"id":"' + calEvent.id + '","userId":"' + calEvent.userId + '","start":"' + formatFglDateTime(calEvent.start) + '", "end":"' + formatFglDateTime(calEvent.end) + '", "title": "' + calEvent.title +'", "eventdesc": "'+ calEvent.eventdesc +'", "eventparent":"'+calEvent.eventparent+'"}');
      gICAPI.Action('update');
    },
    eventMouseover: function(calEvent, $event) {
      displayMessage('<strong>calEvent.title</strong><br/>Start: ' + calEvent.start + '<br/>End: ' + calEvent.end);
      gICAPI.SetFocus();
      gICAPI.SetData('{"id":"' + calEvent.id + '","userId":"' + calEvent.userId + '","start":"' + formatFglDateTime(calEvent.start) + '", "end":"' + formatFglDateTime(calEvent.end) + '", "title": "' + calEvent.title +'", "eventdesc": "'+ calEvent.eventdesc +'", "eventparent":"'+calEvent.eventparent+'"}');
      gICAPI.Action('showdesc');
    }

    /* // Not necessary
    eventMouseout: function(calEvent, $event) {
      displayMessage('<strong>Mouseout Event</strong><br/>Start: ' + calEvent.start + '<br/>End: ' + calEvent.end);
    },
    noEvents: function() {
      displayMessage('There are no events for this week');
    },
    reachedmindate: function($calendar, date) {
      displayMessage('You reached mindate');
    },
    reachedmaxdate: function($calendar, date) {
      displayMessage('You cannot go further');
    }
    */
  });

  function FormatInteger(num, length) {
    var r = "" + num;
    while (r.length < length) {
        r = "0" + r;
    }
    return r;
  }

  function formatFglDateTime(d) {
    return d.getFullYear() + "-" + FormatInteger(d.getMonth()+1,2) + "-" + FormatInteger(d.getDate(),2) + " " + FormatInteger(d.getHours(),2) + ":" + FormatInteger(d.getMinutes(),2) + ":" + FormatInteger(d.getSeconds(),2);
  }

  /**
   * Function to show a 'popup' on bottom (see styles.css for background/color changes)
   * @param message
   */
  function displayMessage(message) {
    $('#message').html(message).fadeIn();
    window.setTimeout(function(){
      $('#message').fadeOut();
    }, 3000);
  }

  // Add the popup container in the page (hidden by default)
  $('<div id="message" class="ui-corner-all"></div>').prependTo($('body'));
});

