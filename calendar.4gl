-- Sample library that uses jquery.weekcalendar.js script

Import util

Public Constant
  recurrenceNone         = 0,
  recurrenceDay          = 1,
  recurrenceWeek         = 2,
  recurrenceMonth        = 3,
  recurrenceYear         = 4

-- That will be translated to a JSON array.
-- Has to be written in lower case or at least first character 
-- in lower case to match JavaScript JSON specification
Public Type
  tEvent        Record
    id            Integer,                  -- id
    userId        Integer,                  -- userId
    start         DateTime Year To Second,  -- start
    end           DateTime Year To Second,  -- end
    recurrence    SmallInt,
    repeattill    Date,
    repmonday     Boolean,
    reptuesday    Boolean,
    repwednesday  Boolean,
    repthursday   Boolean,
    repfriday     Boolean,
    repsaturday   Boolean,
    repsunday     Boolean,
    title         String,                   -- title
    eventdesc     String,
    eventparent   Integer
                End Record,
  tUser         Record
    userid        Integer,                  -- id
    firstname     String,                   -- firstName
    lastname      String                    -- lastName
                End Record
Private Type
  tOptions                   Record
    timeslotsPerHour           SmallInt,
    timeslotHeight             SmallInt,
    use24Hour                  Boolean,
    firstDayOfWeek             SmallInt,
    daysToShow                 SmallInt,
    dateFormat                 String,
    alwaysDisplayTimeMinutes   Boolean,
    useShortDayNames           Boolean,
    defaultEventLength         SmallInt
                             End Record

Private Define
  myCalendar   Dynamic Array Of tEvent,
  myCalOptions tOptions,
  myUsers      Dynamic Array Of tUser,
  dayStartHour DateTime Hour To Second,
  dayEndHour   DateTime Hour To Second

Public Define
  calendarPipe      String,
  currentEventRowNo Integer,
  Debug             Boolean

Public Function init()
  Define
    strDt String

  Let Debug = False
  -- Default values as written in wcweekcalendar.js file
  Let myCalOptions.timeslotsPerHour         = 4
  Let myCalOptions.timeslotHeight           = 20
  Let myCalOptions.use24Hour                = false
  Let myCalOptions.firstDayOfWeek           = 1
  Let myCalOptions.daysToShow               = 7
  Let myCalOptions.dateFormat               = 'M d, Y'
  Let myCalOptions.alwaysDisplayTimeMinutes = True
  Let myCalOptions.useShortDayNames         = False
  Let myCalOptions.defaultEventLength       = 2

  Call ui.Interface.frontCall("webcomponent","call",["formonly.calendarpipe","getStartHour",""],[strDt])
  Let dayStartHour = StrDt||":00:00"
  Call ui.Interface.frontCall("webcomponent","call",["formonly.calendarpipe","getEndHour",""],[strDt])
  Let dayEndHour = strDt||":00:00"
End Function

Public Function redraw( nbDays )
  Define
    nbDays SmallInt

  Call ui.Interface.frontCall("webcomponent","call",["formonly.calendarpipe","redraw",nbDays],[])
End Function

Public Function turnDebugOn( toggle Boolean )
  Let Debug = toggle
End Function

-- User Management
--
Public Function addUser(wcUser)
  Define
    wcUser tUser

  Call myUsers.appendElement()
  Let myUsers[myUsers.getLength()].userId    = wcUser.userId
  Let myUsers[myUsers.getLength()].firstName = wcUser.firstName.trim()
  Let myUsers[myUsers.getLength()].lastName  = wcUser.lastName.trim()
End Function

Public Function ClearUsers()
  Call MyUsers.clear()
End Function

Public Function getUserIdByPosition( pos )
  Define
    pos    Integer,
    userId Integer

  Let userId = Null
  If pos > 0 And pos < myUsers.getLength() Then
    Let userId = myUsers[pos].userid
  End If

  Return userId
End Function

-- Event Management
--

Public Function getEndDayHour()
  Return dayEndHour
End Function

Public Function getStartDayHour()
  Return dayStartHour
End Function

Public Function addEvent(wcEvent)
  Define wcEvent tEvent

  Call myCalendar.appendElement()
  Let myCalendar[myCalendar.getLength()].id          = wcEvent.id
  Let myCalendar[myCalendar.getLength()].userId      = wcEvent.userId
  Let myCalendar[myCalendar.getLength()].start       = wcEvent.start
  Let myCalendar[myCalendar.getLength()].end         = wcEvent.end
  Let myCalendar[myCalendar.getLength()].recurrence  = wcEvent.recurrence
  Let myCalendar[myCalendar.getLength()].repeattill  = wcEvent.repeattill
  Let myCalendar[myCalendar.getLength()].repmonday   = wcEvent.repmonday
  Let myCalendar[myCalendar.getLength()].reptuesday  = wcEvent.reptuesday
  Let myCalendar[myCalendar.getLength()].repwednesday= wcEvent.repwednesday
  Let myCalendar[myCalendar.getLength()].repthursday = wcEvent.repthursday
  Let myCalendar[myCalendar.getLength()].repfriday   = wcEvent.repfriday
  Let myCalendar[myCalendar.getLength()].repsaturday = wcEvent.repsaturday
  Let myCalendar[myCalendar.getLength()].repsunday   = wcEvent.repsunday
  Let myCalendar[myCalendar.getLength()].title       = wcEvent.title.trim()
  Let myCalendar[myCalendar.getLength()].eventDesc   = wcEvent.eventDesc.trim()
  Let myCalendar[myCalendar.getLength()].eventParent = wcEvent.eventParent

  Return myCalendar.getLength()
End Function

Public Function updateWcEvent( pos, wcEvent )
  Define
    pos     Integer,
    wcEvent tEvent

  If pos Is Not Null and pos > 0 Then
    Let myCalendar[pos].id          = wcEvent.id
    Let myCalendar[pos].userId      = wcEvent.userId
    Let myCalendar[pos].start       = wcEvent.start
    Let myCalendar[pos].end         = wcEvent.end
    Let myCalendar[pos].recurrence  = wcEvent.recurrence
    Let myCalendar[pos].repeattill  = wcEvent.repeattill
    Let myCalendar[pos].repmonday   = wcEvent.repmonday
    Let myCalendar[pos].reptuesday  = wcEvent.reptuesday
    Let myCalendar[pos].repwednesday= wcEvent.repwednesday
    Let myCalendar[pos].repthursday = wcEvent.repthursday
    Let myCalendar[pos].repfriday   = wcEvent.repfriday
    Let myCalendar[pos].repsaturday = wcEvent.repsaturday
    Let myCalendar[pos].repsunday   = wcEvent.repsunday
    Let myCalendar[pos].title       = wcEvent.title.trim()
    Let myCalendar[pos].eventDesc   = wcEvent.eventDesc.trim()
    Let myCalendar[pos].eventParent = wcEvent.eventParent
  End If
End Function

Public Function refreshEvents()
  Let calendarPipe = sendEventsToWebComponent()
  If Debug Then Display calendarPipe End If
End Function

Public Function clearEvents()
  Call myCalendar.clear()
End Function

Public Function getEventsCount()
  Return myCalendar.getLength()
End Function

Public Function getEventByIndex( pos )
  Define
    pos    Integer,
    rEvent tEvent

  If pos > myCalendar.getLength() Or pos = 0 Then
    Initialize rEvent To Null
  Else
    Let rEvent.* = myCalendar[pos].*
  End If

  Return rEvent.*
End Function

Public Function getEventIndexById( eventId )
  Define
    eventId Integer

  Return searchEventById( EventId )
End Function

Public Function getEventIdByIndex( pos )
  Define
    pos     Integer,
    eventId Integer

  If pos > myCalendar.getLength() Or pos = 0 Then
    Let eventId = Null
  Else
    Let eventId = myCalendar[pos].id
  End If

  Return eventId
End Function

Public Function removeEventByIndex( Pos )
  Define
    pos Integer,
    id  Integer,
    ret Boolean

  Let ret = False
  If pos > 0 And pos <= myCalendar.getLength() Then
    Let id = myCalendar[Pos].id
    Call ui.Interface.frontCall("webcomponent","call",["formonly.calendarpipe","removeEvent",id],[])
    Call myCalendar.deleteElement( Pos )
    Let calendarPipe = sendEventsToWebComponent()
    Let ret = True
  End If
  Return ret
End Function

Public Dialog dlgCalendar()
  Input By Name calendarPipe Attributes (Without Defaults)
    Before Input
      Call sendUsersToWebComponent()
      Let calendarPipe = sendEventsToWebComponent()

    On Action refresh
      Let calendarPipe = sendEventsToWebComponent()

    On Action caloptions
      Call setCalendarOptions()
      Let calendarPipe = sendEventsToWebComponent()

    On Action oneday
      Let myCalOptions.daysToShow = 1
      Call redraw(1)
      Let calendarPipe = sendEventsToWebComponent()

    On Action threedays
      Let myCalOptions.daysToShow = 3
      Call redraw(3)
      Let calendarPipe = sendEventsToWebComponent()

    On Action fivedays
      Let myCalOptions.daysToShow = 5
      Call redraw(5)
      Let calendarPipe = sendEventsToWebComponent()

    On Action sevendays
      Let myCalOptions.daysToShow = 7
      Call redraw(7)
      Let calendarPipe = sendEventsToWebComponent()

    On Action nowadays
      Call launchFunction( "today" )
      Let calendarPipe = sendEventsToWebComponent()

    On Action previous
      Call launchFunction( "prev" )
      Let calendarPipe = sendEventsToWebComponent()

    On Action next
      Call launchFunction( "next" )
      Let calendarPipe = sendEventsToWebComponent()

  End Input
End Dialog

Public Function cbrecurrence(cbId ui.comboBox)
  Call cbId.clear()
  Call cbId.addItem(recurrenceNone,        %"None")
  Call cbId.addItem(recurrenceDay,         %"Daily")
  Call cbId.addItem(recurrenceWeek,        %"Weekly")
  Call cbId.addItem(recurrenceMonth,       %"Monthly")
  Call cbId.addItem(recurrenceYear,        %"Yearly")
End Function

Public Function cbCalendarUsers(CbId ui.comboBox)
  Define
    i    SmallInt

  Call cbId.clear()
  For i = 1 To myUsers.getLength()
    Call cbId.addItem(myUsers[i].userId,myUsers[i].firstName||" "||myUsers[i].lastName)
  End For
End Function

Public Function readWcEvent(strJsonEvent)
  Define
    strJsonEvent String,
    wcEvent      tEvent

  Call parseJsonEvent(strJsonEvent) Returning wcEvent.*

  Return wcEvent.*
End Function

Public Function completeEvent(wcEvent)
  Define
    wcEvent      tEvent,
    dateStart    Date,
    hourStart    DateTime Hour To Second,
    dateEnd      Date,
    hourEnd      DateTime Hour To Second,
    fullDayLong  Boolean,
    rowNo        Integer

  Let dateStart  = wcEvent.start
  Let hourStart  = wcEvent.start
  Let dateEnd    = wcEvent.end
  Let hourEnd    = wcEvent.end

  Let rowNo = searchEventById(WcEvent.id)
  If rowNo = 0 Then
    Let wcEvent.id = Null
  End If

  Open Window wEventNew With Form "event"

    Let Int_Flag = False
    Input By Name wcEvent.id,
                  wcEvent.userid,
                  dateStart,
                  hourStart,
                  dateEnd,
                  hourEnd,
                  fullDayLong,
                  wcEvent.recurrence,
                  wcEvent.repeatTill,
                  wcEvent.repmonday,
                  wcEvent.reptuesday,
                  wcEvent.repwednesday,
                  wcEvent.repthursday,
                  wcEvent.repfriday,
                  wcEvent.repsaturday,
                  wcEvent.repsunday,
                  wcEvent.title,
                  wcEvent.eventDesc
      Attributes(Without Defaults, Unbuffered)

      Before Input
        If wcEvent.id Is Null Then
          Let wcEvent.eventdesc = ""
          Let fullDayLong = False
          Let wcEvent.recurrence  = 0
          Let wcEvent.repeatTill  = Null
          Let wcEvent.repmonday   = False
          Let wcEvent.reptuesday  = False
          Let wcEvent.repwednesday= False
          Let wcEvent.repthursday = False
          Let wcEvent.repfriday   = False
          Let wcEvent.repsaturday = False
          Let wcEvent.repsunday   = False
          Let wcEvent.eventParent = 0
        Else
          Let wcEvent.eventdesc = myCalendar[rowNo].eventdesc
          Let wcEvent.eventParent = myCalendar[rowNo].eventParent
          If wcEvent.recurrence > recurrenceNone Then
            Call hideObject("field","formonly.repeattill",False)
            Call hideObject("element","lb8",False)
            Call hideObject("element","l10",False)
            Call hideObject("element","l11",False)
            Call hideObject("element","l12",False)
            Call hideObject("element","l13",False)
            Call hideObject("element","l14",False)
            Call hideObject("element","l15",False)
            Call hideObject("element","l16",False)
            Call hideObject("field","formonly.repmonday",False)
            Call hideObject("field","formonly.reptuesday",False)
            Call hideObject("field","formonly.repwednesday",False)
            Call hideObject("field","formonly.repthursday",False)
            Call hideObject("field","formonly.repfriday",False)
            Call hideObject("field","formonly.repsaturday",False)
            Call hideObject("field","formonly.repsunday",False)
          End If
        End If

      On Change recurrence
        If wcEvent.recurrence > recurrenceNone Then
          Call hideObject("field","formonly.repeattill",False)
          Call hideObject("element","lb8",False)
          Call hideObject("element","l10",False)
          Call hideObject("element","l11",False)
          Call hideObject("element","l12",False)
          Call hideObject("element","l13",False)
          Call hideObject("element","l14",False)
          Call hideObject("element","l15",False)
          Call hideObject("element","l16",False)
          Call hideObject("field","formonly.repmonday",False)
          Call hideObject("field","formonly.reptuesday",False)
          Call hideObject("field","formonly.repwednesday",False)
          Call hideObject("field","formonly.repthursday",False)
          Call hideObject("field","formonly.repfriday",False)
          Call hideObject("field","formonly.repsaturday",False)
          Call hideObject("field","formonly.repsunday",False)
          If wcEvent.recurrence = recurrenceDay Then
            Call Dialog.setFieldActive('dateend',False)
          Else
            Call Dialog.setFieldActive('dateend',True)
          End If
        Else
          Call Dialog.setFieldActive('dateend',True)
          Call hideObject("field","formonly.repeattill",True)
          Call hideObject("field","formonly.spacingout",True)
          Call hideObject("element","lb8",True)
          Call hideObject("element","l10",True)
          Call hideObject("element","l11",True)
          Call hideObject("element","l12",True)
          Call hideObject("element","l13",True)
          Call hideObject("element","l14",True)
          Call hideObject("element","l15",True)
          Call hideObject("element","l16",True)
          Call hideObject("field","formonly.repmonday",True)
          Call hideObject("field","formonly.reptuesday",True)
          Call hideObject("field","formonly.repwednesday",True)
          Call hideObject("field","formonly.repthursday",True)
          Call hideObject("field","formonly.repfriday",True)
          Call hideObject("field","formonly.repsaturday",True)
          Call hideObject("field","formonly.repsunday",True)
        End If
        Case
          When wcEvent.recurrence = recurrenceDay
            Let dateEnd = dateStart
            Let wcEvent.repmonday   = True
            Let wcEvent.reptuesday  = True
            Let wcEvent.repwednesday= True
            Let wcEvent.repthursday = True
            Let wcEvent.repfriday   = True
            Let wcEvent.repsaturday = True
            Let wcEvent.repsunday   = True
          When wcEvent.recurrence > recurrenceDay
            Let wcEvent.repmonday   = False
            Let wcEvent.reptuesday  = False
            Let wcEvent.repwednesday= False
            Let wcEvent.repthursday = False
            Let wcEvent.repfriday   = False
            Let wcEvent.repsaturday = False
            Let wcEvent.repsunday   = False
            Case WeekDay(dateStart)
              When 0 -- Sunday
                Let wcEvent.repsunday   = True
              When 1 -- Monday
                Let wcEvent.repmonday   = True
              When 2
                Let wcEvent.reptuesday  = True
              When 3
                Let wcEvent.repwednesday= True
              When 4
                Let wcEvent.repthursday = True
              When 5
                Let wcEvent.repfriday   = True
              When 6
                Let wcEvent.repsaturday = True
            End Case
          Otherwise
            Let dateEnd = dateStart
            Let wcEvent.repeatTill  = Null
            Let wcEvent.repmonday   = False
            Let wcEvent.reptuesday  = False
            Let wcEvent.repwednesday= False
            Let wcEvent.repthursday = False
            Let wcEvent.repfriday   = False
            Let wcEvent.repsaturday = False
            Let wcEvent.repsunday   = False
        End Case
        If wcEvent.recurrence > recurrenceNone Then
          Next Field repeatTill
        End If

      On Change repmonday,reptuesday,repwednesday,repthursday,repfriday,repsaturday,repsunday
        If Not (wcEvent.repmonday Or wcEvent.reptuesday Or wcEvent.repwednesday Or wcEvent.repthursday Or wcEvent.repfriday Or wcEvent.repsaturday Or wcEvent.repsunday) Then
          Error %"At least one day needs to be selected"
          Case WeekDay(dateStart)
            When 0 -- Sunday
              Let wcEvent.repsunday   = True
            When 1 -- Monday
              Let wcEvent.repmonday   = True
            When 2
              Let wcEvent.reptuesday  = True
            When 3
              Let wcEvent.repwednesday= True
            When 4
              Let wcEvent.repthursday = True
            When 5
              Let wcEvent.repfriday   = True
            When 6
              Let wcEvent.repsaturday = True
          End Case
          Next Field Current
        End If

      On Change fullDayLong
        If fullDayLong Then
          Let hourStart = dayStartHour
          Let hourEnd   = dayEndHour
          Call Dialog.setFieldActive('hourstart',False)
          Call Dialog.setFieldActive('hourend',False)
        Else
          Call Dialog.setFieldActive('hourstart',True)
          Call Dialog.setFieldActive('hourend',True)
        End If

      On Change dateStart
        If dateEnd Is Not Null Then
          If dateEnd < dateStart Then
            Error %"Start date can't be higher than end date"
            Next Field Current
          End If
        End If
        If wcEvent.recurrence = recurrenceDay Then
          Let dateEnd = dateStart
        End If

      On Change dateEnd
        If dateEnd < dateStart Then
          Error %"End date can't be lower than start date"
          Next Field Current
        End If
        If checkEventColisions(wcEvent.id,wcEvent.userId,dateStart,hourStart,dateEnd,hourEnd) Then
          Message %"Warning: This event runs into colision with another"
        End If

      On Change hourEnd
        If dateEnd = dateStart Then
          If hourEnd < hourStart Then
            Error %"End Hour can't be lower than start hour"
            Next Field Current
          End If
        End If
        If checkEventColisions(wcEvent.id,wcEvent.userId,dateStart,hourStart,dateEnd,hourEnd) Then
          Message %"Warning: This event runs into colision with another"
        End If

      On Change repeatTill
        If wcEvent.repeattill <= dateEnd Then
          Error %"End date can't be equal or greater than end of reccurence date"
          Next Field Current
        End If

      On Action accept
        If checkEventColisions(wcEvent.id,wcEvent.userId,dateStart,hourStart,dateEnd,hourEnd) Then
          Error %"Error: This event runs into colision with another"
          Next Field dateStart
        End If
        If wcEvent.repeatTill Is Null And wcEvent.recurrence > recurrenceNone Then
          Next Field repeatTill
        End If
        Call Dialog.accept()

    End Input

  Close Window wEventNew

  Let wcEvent.start = formatWcDateHour(dateStart,hourStart)
  Let wcEvent.end   = formatWcDateHour(dateEnd,hourEnd)
  Return Not Int_Flag, rowNo,wcEvent.*
End Function

Public Function formatWcDateHour(da,hr)
  Define
    da Date,
    hr DateTime Hour To Second,
    dt DateTime Year To Second

  Let dt = da
  Let dt = dt + (hr - "0")
  Return dt
End Function

Public Function checkEventColisions(eventId,userId,dateStart,hourStart,dateEnd,hourEnd)
  Define
    eventId   Integer,
    userId    Integer,
    dateStart Date,
    hourStart Datetime Hour To Second,
    dateEnd   Date,
    hourEnd   DateTime Hour To Second,
    firstId   Integer,
    dt        Dynamic Array Of Record
      id        Integer,
      dtStart   Datetime Year To Second,
      dtEnd     Datetime Year To second
              End Record,
    retCod    Boolean,
    i,j       Integer

  Message ""
  Let retCod = False
  For i=0 To dateEnd-dateStart
    Let dt[i+1].dtStart = formatWcDateHour(dateStart+i,hourStart)
    Let dt[i+1].dtEnd   = formatWcDateHour(dateStart+i,hourEnd)
  End For
  Let firstId = 0
  For i=1 To myCalendar.getLength()
    If myCalendar[i].userId = userId And myCalendar[i].id <> eventId Then
      If firstId = 0 And myCalendar[i].eventparent > 0 Then
        Let firstId = getFirstLinkEvent(myCalendar[i].id)
      End If
      If firstId <> eventId Then
        For j=1 To dt.getLength()
          If (dt[j].dtStart <= myCalendar[i].start And dt[j].dtEnd > myCalendar[i].start)
            Or (dt[j].dtStart > myCalendar[i].start And dt[j].dtEnd <= myCalendar[i].end)
            Or (dt[j].dtStart < myCalendar[i].end And dt[j].dtEnd >= myCalendar[i].end) Then
            Let retCod = True
            Exit For
          End If
        End For
      End If
      If retCod Then
        Exit For
      End If
    End If
  End For

  Return retCod
End Function

-- Private functions
--
Public Function launchFunction( fct )
  Define
    fct String

  Call ui.Interface.frontCall("webcomponent","call",["formonly.calendarpipe","launchFunction",fct],[])
End Function

Private Function hideObject(objectType String, objectName String, toggle Boolean)
  Define
    fId ui.Form

  Try
    Let fId = ui.Window.getCurrent().getForm()
    Case objectType
      When "field"
        Call fId.setFieldHidden(objectName,toggle)
      When "element"
        Call fId.setElementHidden(objectName,toggle)
    End Case
  Catch
  End Try
End Function

Private Function setCalendarOptions()
  Open Window wCalOptions With Form "options"

    Let Int_Flag = False
    Input By Name myCalOptions.* Attributes (Unbuffered, Without Defaults)

  Close Window wCalOptions
  If Not Int_Flag Then
    Let calendarPipe = sendEventsToWebComponent()
    Call launchFunction("today")
  End If
End Function

Private Function getFirstLinkEvent(eventId)
  Define
    eventId Integer,
    Id      Integer,
    i       Integer

  Let id = 0
  For i = 1 To myCalendar.getLength()
    If myCalendar[i].id = eventId Then
      If myCalendar[i].eventparent = eventId Then
        Let id = eventId
        Exit For
      Else
        If myCalendar[i].eventparent > 0 Then
          Let id = getFirstLinkEvent(myCalendar[i].eventparent)
          Exit For
        Else
          Exit For
        End If
      End If
    End If
  End For

  Return id
End Function

Private Function sendUsersToWebComponent()
  Define
    jsonUsers    util.JSONArray,
    strJsonUsers String

  If myUsers.getLength() > 0 Then
    Let jsonUsers = util.JSONArray.fromFGL(MyUsers)
    Let strJsonUsers = JsonUsers.toString()
  Else
    Let strJsonUsers = "[]"
  End If
  Call ui.Interface.frontCall("webcomponent","call",["formonly.calendarpipe","setFglUsers",strJsonUsers],[])
End Function

Private Function sendEventsToWebComponent()
  Define
    jsonEvents    util.JSONArray,
    jsonOptions   util.JSONObject,
    strJsonEvents String

  Let jsonOptions   = util.JSONObject.fromFGL(myCalOptions)
  If myCalendar.getLength() > 0 Then
    Let jsonEvents    = util.JSONArray.fromFGL(myCalendar)
    Let strJsonEvents = '{"options":',jsonOptions.toString(),',"events":',jsonEvents.toString(),'}'
  Else
    Let strJsonEvents = '{"options":',jsonOptions.toString(),',"events":[]}'
  End If

  If Debug Then Display StrJsonEvents End If
  Return  strJsonEvents
End Function

Public Function displayEventDetails(rowNo)
  Define
    rowNo        Integer

  If rowNo Is Null Then
    Error "Event Id is Null, something went wrong"
    Let rowNo = 0
  End If
  If rowNo = 0 Then
    Display False To recurrent
    Display %"Undefined" To formonly.eventtitle
    Display %"Undefined" To formonly.eventdesc
  Else
    Display Iif(myCalendar[rowNo].eventparent>0,True,False) To recurrent
    Display myCalendar[rowNo].title     To formonly.eventtitle
    Display myCalendar[rowNo].eventdesc To formonly.eventdesc
  End If

  Return rowNo
End Function

Private Function searchEventById( EventId )
  Define
    eventId Integer,
    rowNo   Integer

  If myCalendar.getLength() = 0 Then
    Let rowNo = 0
  Else
    If eventId Is Null Then
      Let rowNo = 0
    Else
      For rowNo = 1 To myCalendar.getLength()
        If myCalendar[rowNo].id = eventId Then
          Exit For
        End If
      End For
      If rowNo = myCalendar.getLength() And myCalendar[rowNo].id <> EventId Then
        Let rowNo = 0
      End If
    End If
  End If

  Return rowNo
End Function

Private Function parseJsonEvent(strJsonEvent)
  Define
    strJsonEvent  String,
    wcEvent       tEvent,
    jsonEvent     util.JSONObject

  Initialize wcEvent To Null
  If strJsonEvent.getLength() > 0 Then
    Let jsonEvent = util.JSONObject.parse(strJsonEvent)
    Let wcEvent.Id          = jsonEvent.get("id")
    Let wcEvent.UserId      = jsonEvent.get("userId")
    Let wcEvent.Start       = jsonEvent.get("start")
    Let wcEvent.End         = jsonEvent.get("end")
    Let wcEvent.recurrence  = jsonEvent.get("recurrence")
    Let wcEvent.repeattill  = jsonEvent.get("repeattill")
    Let wcEvent.repmonday   = jsonEvent.get("repmonday")
    Let wcEvent.reptuesday  = jsonEvent.get("reptuesday")
    Let wcEvent.repwednesday= jsonEvent.get("repwednesday")
    Let wcEvent.repthursday = jsonEvent.get("repthursday")
    Let wcEvent.repfriday   = jsonEvent.get("repfriday")
    Let wcEvent.repsaturday = jsonEvent.get("repsaturday")
    Let wcEvent.repsunday   = jsonEvent.get("repsunday")
    Let wcEvent.Title       = jsonEvent.get("title")
    Let wcEvent.eventdesc   = jsonEvent.get("eventdesc")
    Let wcEvent.eventparent = jsonEvent.get("eventparent")
  End If

  Return wcEvent.*
End Function