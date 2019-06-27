-- ChG: Sample program that uses calendar.4gl library

Import FGL calendar

Type
  tDbEvent      Record
    eventId       Integer,
    userId        Integer,
    dateStart     Date,
    hourStart     DateTime Hour To Second,
    dateEnd       Date,
    hourEnd       DateTime Hour To Second,
    recurrence    smallInt,
    repeattill    Date,
    repmonday     Boolean,
    reptuesday    Boolean,
    repwednesday  Boolean,
    repthursday   Boolean,
    repfriday     Boolean,
    repsaturday   Boolean,
    repsunday     Boolean,
    eventTitle    Char(50),
    eventDesc     Char(200),
    eventParent   Integer
                End Record

Main
  Define
    dateStart  Date,
    dateEnd    Date,
    hourStart  DateTime Hour To Second,
    hourEnd    DateTime Hour To Second,
    bkpstart   DateTime Year To Second,
    bkpend     DateTime Year To Second,
    wEvent     calendar.tEvent,
    retCod     Integer,
    aEvents    Dynamic Array Of String,
    aTtyAttr   Dynamic Array Of String

  Call ui.Interface.loadStyles("wc_weekcalendar")

  -- Database used is Sqlite with in-memory feature
  -- DB definition can be found at the bottom of this file.
  Call connectDb()

  Close Window Screen

  Open Window wAgenda With Form "agenda"

    Call calendar.init()
    Call initUsers()
    Call initEvents()

--    Call calendar.turnDebugOn(True) --needs to be called after calendar.init()
    Dialog Attributes (Unbuffered)
      SubDialog calendar.dlgCalendar
      Display Array aEvents To srEvents.*
      End Display

      Before Dialog
        Call Dialog.setArrayAttributes("srevents",aTtyAttr)
        Call getEventList(aEvents,aTtyAttr,calendar.getUserIdByPosition(1))
        If aEvents.getLength() >= 2 Then
          Call Dialog.setCurrentRow("srevents",2)
        End If

      On Action showDesc
        Call calendar.readWcEvent(calendar.calendarPipe) Returning wEvent.*
        Let calendar.currentEventRowNo = calendar.displayEventDetails(wEvent.id)
        Call getEventList(aEvents,aTtyAttr,wEvent.userId)
        If aEvents.getLength() >= 2 Then
          Call Dialog.setCurrentRow("srevents",2)
        End If

      On Action new
        Let calendar.currentEventRowNo = calendar.displayEventDetails(0)
        Call calendar.readWcEvent(calendar.calendarPipe) Returning wEvent.*
        Call calendar.completeEvent(wEvent.*)
          Returning retCod,calendar.currentEventRowNo,wEvent.*
        If retCod Then
          Let wEvent.id = getNewEvenId()
          Let dateStart = wEvent.start
          Let hourStart = wEvent.start
          Let hourEnd   = wEvent.end
          Let dateEnd   = wEvent.end
          Case wEvent.recurrence
            When calendar.recurrenceNone
              Let wEvent.eventParent = 0
              If dateEnd > dateStart Then
                Let wEvent.eventParent = wEvent.id
              End If
              Call addSimpleEvent(wEvent.*,wEvent.start,wEvent.end,hourEnd,hourStart) Returning wEvent.*
            When calendar.recurrenceDay
              Let wEvent.end = calendar.formatWcDateHour(DateStart,HourEnd)
              Let wEvent.eventParent = wEvent.id
              Call addSimpleEvent(wEvent.*,wEvent.start,wEvent.repeattill,hourEnd,hourStart) Returning wEvent.*
            When calendar.recurrenceWeek
              Let wEvent.eventParent = wEvent.id
              While dateStart <= wEvent.repeattill
                Let bkpstart = wEvent.start
                Let bkpend   = wEvent.end
                Let dateEnd   = wEvent.end
                Call addSimpleEvent(wEvent.*,wEvent.start,wEvent.start+( Interval ( 1 ) Day To Day * 6 ),hourEnd,hourStart) Returning wEvent.*
                Let wEvent.start = bkpstart + ( Interval ( 1 ) Day To Day * 7 )
                Let wEvent.end   = bkpend   + ( Interval ( 1 ) Day To Day * 7 )
                Let dateStart = wEvent.start
              End While
            When calendar.recurrenceMonth
              Let wEvent.eventParent = wEvent.id
              While dateStart <= wEvent.repeattill
                Let bkpstart = wEvent.start
                Let bkpend   = wEvent.end
                Let dateEnd   = wEvent.end
                Call addSimpleEvent(wEvent.*,wEvent.start,wEvent.start+( Interval ( 1 ) Day To Day * 6 ),hourEnd,hourStart) Returning wEvent.*
                Let wEvent.start = bkpstart + ( Interval ( 1 ) Month To Month )
                Let wEvent.end   = bkpend   + ( Interval ( 1 ) Month To Month )
                Let dateStart = wEvent.start
              End While
            When calendar.recurrenceYear
              Let wEvent.eventParent = wEvent.id
              While dateStart <= wEvent.repeattill
                Let bkpstart = wEvent.start
                Let bkpend   = wEvent.end
                Let dateEnd   = wEvent.end
                Call addSimpleEvent(wEvent.*,wEvent.start,wEvent.start+( Interval ( 1 ) Day To Day * 6 ),hourEnd,hourStart) Returning wEvent.*
                Let wEvent.start = bkpstart + ( Interval ( 1 ) Year To Year )
                Let wEvent.end   = bkpend   + ( Interval ( 1 ) Year To Year )
                Let dateStart = wEvent.start
              End While
          End Case
        End If
        Call calendar.refreshEvents()
        Call getEventList(aEvents,aTtyAttr,wEvent.userId)
        If aEvents.getLength() >= 2 Then
          Call Dialog.setCurrentRow("srevents",2)
        End If

      -- drag&drop event or change length of event
      On Action move
        Call calendar.readWcEvent(calendar.calendarPipe) Returning wEvent.*
        If wEvent.eventparent > 0 Then
          Call getRecurrentEventData(wEvent.*) Returning wEvent.*
        End If
        If calendar.checkEventColisions(wEvent.id,wEvent.userId,wEvent.start,wEvent.start,wEvent.end,wEvent.end) Then
          Error %"Warning: This event runs into colision with another"
        Else
          Call modifyEvent( wEvent.* )
        End If
        Call calendar.refreshEvents()
        Call getEventList(aEvents,aTtyAttr,wEvent.userId)
        If aEvents.getLength() >= 2 Then
          Call Dialog.setCurrentRow("srevents",2)
        End If

      -- click an event
      On Action update
        Call calendar.readWcEvent(calendar.calendarPipe) Returning wEvent.*
        If wEvent.eventparent > 0 Then
          Call getRecurrentEventData(wEvent.*) Returning wEvent.*
        End If
        Call calendar.completeEvent(wEvent.*)
          Returning RetCod,calendar.currentEventRowNo,wEvent.*
        If retCod Then
          Call modifyEvent( wEvent.* )
        End If
        Call calendar.refreshEvents()
        Call getEventList(aEvents,aTtyAttr,wEvent.userId)
        If aEvents.getLength() >= 2 Then
          Call Dialog.setCurrentRow("srevents",2)
        End If

      -- Pass the mouse cursor over the event and press delete button
      On Action remove
        If calendar.currentEventRowNo Is Not Null And calendar.currentEventRowNo <> 0 Then
          Call calendar.getEventByIndex( calendar.currentEventRowNo ) Returning wEvent.*
          If wEvent.id Is Not Null Then
            Let wEvent.id = getEventFirstLink( wEvent.Id )
            While True
              Let retCod = removeEvent( wEvent.id )
              Let wEvent.id = getEventNextLink( wEvent.Id )
              If wEvent.id = 0 Then
                Exit While
              End If
            End While
          End If
          Let calendar.currentEventRowNo = calendar.displayEventDetails(0)
          Call getEventList(aEvents,aTtyAttr,wEvent.userId)
          If aEvents.getLength() >= 2 Then
            Call Dialog.setCurrentRow("srevents",2)
          End If
        End If

      On Action close
        Exit Dialog
    End Dialog

  Close Window wAgenda
End Main

Function addSimpleEvent( wEvent calendar.tEvent, dateStart Date, dateTill Date, hourEnd DateTime Hour To Second, hourStart DateTime Hour To Second )
  Define
    doIt Boolean,
    dts  Date,
    dte  Date

  Let dts = wEvent.start
  Let dte = wEvent.end
  If dte > dts Then
    Let wEvent.end = calendar.formatWcDateHour(wEvent.start,calendar.getEndDayHour())
  End If
  While dateStart <= dateTill
    If wEvent.recurrence = calendar.recurrenceNone Then
      Let doIt = True
    Else
      Case 
        When wEvent.repsunday    And WeekDay(wEvent.start) = 0
          Let doIt = True
        When wEvent.repmonday    And WeekDay(wEvent.start) = 1
          Let doIt = True
        When wEvent.reptuesday   And WeekDay(wEvent.start) = 2
          Let doIt = True
        When wEvent.repwednesday And WeekDay(wEvent.start) = 3
          Let doIt = True
        When wEvent.repthursday  And WeekDay(wEvent.start) = 4
          Let doIt = True
        When wEvent.repfriday    And WeekDay(wEvent.start) = 5
          Let doIt = True
        When wEvent.repsaturday  And WeekDay(wEvent.start) = 6
          Let doIt = True
        When dte > dts And dateStart <= dte
          Let doIt = True
        Otherwise
          Let doIt = False
      End Case
    End If
    If doIt Then
      If insertDbEvent(wEvent.*) Then
        Let calendar.currentEventRowNo = calendar.addEvent(wEvent.id,
                                   wEvent.userId,
                                   wEvent.start,
                                   wEvent.end,
                                   wEvent.recurrence,
                                   wEvent.repeattill,
                                   wEvent.repmonday,
                                   wEvent.reptuesday,
                                   wEvent.repwednesday,
                                   wEvent.repthursday,
                                   wEvent.repfriday,
                                   wEvent.repsaturday,
                                   wEvent.repsunday,
                                   wEvent.title,
                                   wEvent.eventDesc,
                                   wEvent.eventParent)
      End If
      Let wEvent.eventParent = wEvent.id
      Let wEvent.id = getNewEvenId()
    End If
    Let wEvent.start = wEvent.start + Interval ( 1 ) Day To Day
    Let wEvent.end   = wEvent.end   + Interval ( 1 ) Day To Day
    Let dateStart = wEvent.start
    If dte > dts Then
      Let wEvent.start = calendar.formatWcDateHour(wEvent.start,calendar.getStartDayHour())
    End If
    If dateStart = dte Then
      Let wEvent.end = calendar.formatWcDateHour(dateStart,hourEnd)
    End If
  End While

  Return wEvent.*
End Function

-- Select start date, end date and first chaine id of an event
Function getRecurrentEventData(wEvent)
  Define
    dateStart  Date,
    wEvent     calendar.tEvent,
    dbEvent    tDbEvent,
    diffDays   Integer

  Let dateStart = wEvent.start
  Call selectEvent( wEvent.id ) Returning dbEvent.*
  If dateStart <> dbEvent.dateStart Then
    -- Event has been dragged
    Let diffDays = dateStart - dbEvent.dateStart
  Else
    Let diffDays = 0
  End If
  Let wEvent.id = getEventFirstLink( wEvent.Id )
  Call selectEvent( wEvent.id ) Returning dbEvent.*
  Let wEvent.start = calendar.formatWcDateHour(dbEvent.dateStart+diffDays,wEvent.start)
  Let dbEvent.eventId = getEventLastLink( wEvent.id )
  Call selectEvent( dbEvent.eventid ) Returning dbEvent.*
  Let wEvent.end = calendar.formatWcDateHour(dbEvent.dateEnd+diffDays,wEvent.end)

  Return wEvent.*
End Function

-- Manages event modification in DB and WC and cares about recurrence
Function modifyEvent( wEvent calendar.tEvent )
  Define
    dateStart  Date,
    dateEnd    Date,
    hourStart  DateTime Hour To Second,
    hourEnd    DateTime Hour To Second,
    bkpstart   DateTime Year To Second,
    bkpend     DateTime Year To Second,
    retCod     Integer,
    eId        Integer

  -- Remove chaine
  If wEvent.id Is Not Null Then
    Let eId = getEventFirstLink( wEvent.Id )
    While True
      Let retCod = removeEvent( eId )
      Let eId = getEventNextLink( eId )
      If eId = 0 Then
        Exit While
      End If
    End While
  End If

  -- build chaine in new
  Let dateStart = wEvent.start
  Let hourStart = wEvent.start
  Let hourEnd   = wEvent.end
  Let dateEnd   = wEvent.end
  Case wEvent.recurrence
    When calendar.recurrenceNone
      Let wEvent.eventParent = 0
      If dateEnd > dateStart Then
        Let wEvent.eventParent = wEvent.id
      End If
      Call addSimpleEvent(wEvent.*,wEvent.start,wEvent.end,hourEnd,hourStart) Returning wEvent.*
    When calendar.recurrenceDay
      Let wEvent.end = calendar.formatWcDateHour(DateStart,HourEnd)
      Let wEvent.eventParent = wEvent.id
      Call addSimpleEvent(wEvent.*,wEvent.start,wEvent.repeattill,hourEnd,hourStart) Returning wEvent.*
    When calendar.recurrenceWeek
      Let wEvent.eventParent = wEvent.id
      While dateStart <= wEvent.repeattill
        Let bkpstart = wEvent.start
        Let bkpend   = wEvent.end
        Let dateEnd   = wEvent.end
        Call addSimpleEvent(wEvent.*,wEvent.start,wEvent.start+( Interval ( 1 ) Day To Day * 6 ),hourEnd,hourStart) Returning wEvent.*
        Let wEvent.start = bkpstart + ( Interval ( 1 ) Day To Day * 7 )
        Let wEvent.end   = bkpend   + ( Interval ( 1 ) Day To Day * 7 )
        Let dateStart = wEvent.start
      End While
    When calendar.recurrenceMonth
      Let wEvent.eventParent = wEvent.id
      While dateStart <= wEvent.repeattill
        Let bkpstart = wEvent.start
        Let bkpend   = wEvent.end
        Let dateEnd   = wEvent.end
        Call addSimpleEvent(wEvent.*,wEvent.start,wEvent.start+( Interval ( 1 ) Day To Day * 6 ),hourEnd,hourStart) Returning wEvent.*
        Let wEvent.start = bkpstart + ( Interval ( 1 ) Month To Month )
        Let wEvent.end   = bkpend   + ( Interval ( 1 ) Month To Month )
        Let dateStart = wEvent.start
      End While
    When calendar.recurrenceYear
      Let wEvent.eventParent = wEvent.id
      While dateStart <= wEvent.repeattill
        Let bkpstart = wEvent.start
        Let bkpend   = wEvent.end
        Let dateEnd   = wEvent.end
        Call addSimpleEvent(wEvent.*,wEvent.start,wEvent.start+( Interval ( 1 ) Day To Day * 6 ),hourEnd,hourStart) Returning wEvent.*
        Let wEvent.start = bkpstart + ( Interval ( 1 ) Year To Year )
        Let wEvent.end   = bkpend   + ( Interval ( 1 ) Year To Year )
        Let dateStart = wEvent.start
      End While
  End Case
End Function

-- Does the modification of a given event
Function updateEvent( wEvent )
  Define
    wEvent    calendar.tEvent,
    dateStart Date,
    hourEnd   DateTime Hour To Second,
    pos       Integer

  Let pos = False
  Let dateStart  = wEvent.start
  Let hourEnd    = wEvent.end
  Let wEvent.end = calendar.formatWcDateHour(dateStart,hourEnd)
  If updateDbEvent(wEvent.*) Then
    Let pos = calendar.getEventIndexById( wEvent.id )
    Call calendar.updateWcEvent( pos, wEvent.* )
    Let pos = True
  End If

  Return pos
End Function

-- Does the removal of a given event
Function removeEvent( eventId )
  Define
    eventId     Integer,
    pos         Integer,
    retCod      Boolean

  Let retCod = True

  If deleteDbEvent( eventId ) Then
    Let pos = calendar.getEventIndexById( eventId )
    If calendar.removeEventByIndex( pos ) Then
    End If
  End If

  Return retCod
End Function

Function formatToDbEvent( wcEvent )
  Define
    wcEvent calendar.tEvent,
    dbEvent tDbEvent

  Let dbEvent.eventId     = wcEvent.id
  Let dbEvent.userId      = wcEvent.userId
  Let dbEvent.dateStart   = wcEvent.start
  Let dbEvent.hourStart   = wcEvent.start
  Let dbEvent.dateEnd     = wcEvent.end
  Let dbEvent.hourEnd     = wcEvent.end
  Let dbEvent.recurrence  = wcEvent.recurrence
  Let dbEvent.repeattill  = wcEvent.repeattill
  Let dbEvent.repmonday   = wcEvent.repmonday
  Let dbEvent.reptuesday  = wcEvent.reptuesday
  Let dbEvent.repwednesday= wcEvent.repwednesday
  Let dbEvent.repthursday = wcEvent.repthursday
  Let dbEvent.repfriday   = wcEvent.repfriday
  Let dbEvent.repsaturday = wcEvent.repsaturday
  Let dbEvent.repsunday   = wcEvent.repsunday
  Let dbEvent.eventTitle  = wcEvent.title
  Let dbEvent.eventDesc   = wcEvent.eventdesc
  Let dbEvent.eventParent = wcEvent.eventParent

  Return dbEvent.*
End Function

Function formatToWcEvent( dbEvent )
  Define
    dbEvent tDbEvent,
    wcEvent calendar.tEvent

  Let wcEvent.id          = dbEvent.eventId
  Let wcEvent.userId      = dbEvent.userId
  Let wcEvent.start       = formatWcDateHour(dbEvent.dateStart,dbEvent.hourStart)
  Let wcEvent.end         = formatWcDateHour(dbEvent.dateEnd,dbEvent.hourEnd)
  Let wcEvent.recurrence  = dbEvent.recurrence
  Let wcEvent.repeattill  = dbEvent.repeattill
  Let wcEvent.repmonday   = dbEvent.repmonday
  Let wcEvent.reptuesday  = dbEvent.reptuesday
  Let wcEvent.repwednesday= dbEvent.repwednesday
  Let wcEvent.repthursday = dbEvent.repthursday
  Let wcEvent.repfriday   = dbEvent.repfriday
  Let wcEvent.repsaturday = dbEvent.repsaturday
  Let wcEvent.repsunday   = dbEvent.repsunday
  Let wcEvent.title       = dbEvent.eventTitle
  Let wcEvent.eventDesc   = dbEvent.eventDesc
  Let wcEvent.eventParent = dbEvent.eventParent

  Return wcEvent.*
End Function

Function getEventFirstLink( id )
  Define
    id       Integer,
    prevLink Integer

  Let prevLink = getEventPreviousLink( id )
  If prevLink <> 0 Then
    If prevLink <> id Then
      Let prevLink = getEventFirstLink( prevLink )
    End If
  Else
    Let prevLink = id
  End If

  Return prevLink
End Function

Function getEventLastLink( id )
  Define
    id       Integer,
    nextLink Integer

  Let nextLink = getEventNextLink( id )
  If nextLink <> 0 Then
    Let nextLink = getEventLastLink( nextLink )
  Else
    Let nextLink = id
  End If

  Return nextLink
End Function

Function getEventList(aEvents,aTtyAttr,userId)
  Define
    aEvents    Dynamic Array Of String,
    aTtyAttr   Dynamic Array Of String,
    userId     Integer,
    dbEvent    tDbEvent,
    timeTitles SmallInt

  Call aEvents.clear()
  Call aTtyAttr.clear()

  Let timeTitles = 0

  Declare cUserEvents Cursor From "Select * From events Where userid = ? Order By datestart,hourstart"
  Foreach cUserEvents Using userId Into dbEvent.*
    Case
      When dbEvent.dateStart < Today-1 And timeTitles < 1
        Call aEvents.appendElement()
        Let aTtyAttr[aEvents.getLength()] = "blue reverse"
        Let aEvents[aEvents.getLength()] = %"Past"
        Let timeTitles = 1
      When dbEvent.dateStart = Today-1 And timeTitles < 2
        Call aEvents.appendElement()
        Let aTtyAttr[aEvents.getLength()] = "blue reverse"
        Let aEvents[aEvents.getLength()] = %"Yesterday"
        Let timeTitles = 2
      When dbEvent.dateStart = Today And timeTitles < 3
        Call aEvents.appendElement()
        Let aTtyAttr[aEvents.getLength()] = "blue reverse"
        Let aEvents[aEvents.getLength()] = %"Today"
        Let timeTitles = 3
      When dbEvent.dateStart = Today+1 And timeTitles < 4
        Call aEvents.appendElement()
        Let aTtyAttr[aEvents.getLength()] = "blue reverse"
        Let aEvents[aEvents.getLength()] = %"Tomorrow"
        Let timeTitles = 4
      When dbEvent.dateStart > Today+1 And timeTitles < 5
        Call aEvents.appendElement()
        Let aTtyAttr[aEvents.getLength()] = "blue reverse"
        Let aEvents[aEvents.getLength()] = %"Coming Next"
        Let timeTitles = 5
    End Case
    Call aEvents.appendElement()
    Let aEvents[aEvents.getLength()] = dbEvent.eventTitle
  End Foreach
  Free cUserEvents
End Function

-- SQL
--
Function initUsers()
  Define
    userid    Integer,
    firstName Char(20),
    lastName  Char(20)

  Call calendar.clearUsers()
  Declare cUsers Cursor From "Select userid,firstname,lastname From users"
  Foreach cUsers Into userid,firstname,lastname
    Call calendar.addUser(userid,firstName,lastName)
  End Foreach
  Free cUsers
End Function

Function initEvents()
  Define
    dbEvent tDbEvent,
    pos     Integer

  Call calendar.clearEvents()
  Declare cEvents Cursor From "Select * From events Order By eventid"
  Foreach cEvents Into dbEvent.*
    Let pos = calendar.addEvent(dbEvent.eventId,
                                dbEvent.userId,
                                calendar.formatWcDateHour(dbEvent.dateStart,dbEvent.hourStart),
                                calendar.formatWcDateHour(dbEvent.dateEnd,dbEvent.hourEnd),
                                dbEvent.recurrence,
                                dbEvent.repeattill,
                                dbEvent.repmonday,
                                dbEvent.reptuesday,
                                dbEvent.repwednesday,
                                dbEvent.repthursday,
                                dbEvent.repfriday,
                                dbEvent.repsaturday,
                                dbEvent.repsunday,
                                dbEvent.eventTitle,
                                dbEvent.eventDesc,
                                dbEvent.eventParent
                               )
  End Foreach
End Function

Function getNewEvenId()
  Define
    myEventId Integer

  Select max(eventid)+1 Into myEventId From events
  Return Nvl(myEventId,1)
End Function

Function insertDbEvent( wcEvent )
  Define
    wcEvent calendar.tEvent,
    dbEvent tDbEvent,
    retCod  Boolean

  Call formatToDbEvent(wcEvent.*) Returning dbEvent.*

  Let retCod = True
  Try
    Insert Into events Values (dbEvent.*)
  Catch
    Display "SQL Insert Error: ",Sqlca.sqlcode," ",SqlErrMessage
    Let retCod = False
  End Try

  Return retCod
End Function

Function updateDbEvent( wcEvent )
  Define
    wcEvent calendar.tEvent,
    dbEvent tDbEvent,
    retCod  Boolean

  Call formatToDbEvent(WcEvent.*) Returning dbEvent.*

  Let retCod = True
  Try
    Update events
      Set userId      = dbEvent.userId,
          dateStart   = dbEvent.dateStart,
          hourStart   = dbEvent.hourStart,
          dateEnd     = dbEvent.dateEnd,
          hourEnd     = dbEvent.hourEnd,
          recurrence  = dbEvent.recurrence,
          repmonday   = dbEvent.repmonday,
          reptuesday  = dbEvent.reptuesday,
          repwednesday= dbEvent.repwednesday,
          repthursday = dbEvent.repthursday,
          repfriday   = dbEvent.repfriday,
          repsaturday = dbEvent.repsaturday,
          repsunday   = dbEvent.repsunday,
          eventTitle  = dbEvent.eventTitle,
          eventDesc   = dbEvent.eventDesc,
          eventParent = dbEvent.eventParent
    Where events.eventId = dbEvent.eventId
  Catch
    Display "SQL Update Error: ",Sqlca.sqlcode," ",SqlErrMessage
    Let retCod = False
  End Try

  Return retCod
End Function

Function chainEvent( id, parent )
  Define
    id     Integer,
    parent Integer

  Try
    Update events
      Set eventParent = parent
    Where events.eventId = id
  Catch
    Display "SQL Update Error: ",Sqlca.sqlcode," ",SqlErrMessage
  End Try
End Function

Function deleteDbEvent( eventId )
  Define
    eventId    Integer,
    retCod     Boolean

  Let retCod = True

  Try
    Delete From events Where events.eventid = eventId
  Catch
    Display "SQL Delete Error: ",Sqlca.sqlcode," ",SqlErrMessage
    Let retCod = False
  End Try

  Return retCod
End Function

Function getEventPreviousLink( id )
  Define
    id       Integer,
    prevLink Integer

  Select eventparent
    Into prevLink
    From events
   Where events.eventid = id

  Return prevLink
End Function

Function getEventNextLink( id )
  Define
    id       Integer,
    nextLink Integer

  If id = 0 Then
    Let nextLink = 0
  Else
    Try
      Select eventid
        Into nextLink
        From events
       Where events.eventParent = id And events.eventid <> id
    Catch
      Display "SQL Select Next Link Error: ",Sqlca.sqlcode," ",SqlErrMessage
    End Try
    If Sqlca.sqlcode = 100 Then
      Let nextLink = 0
    End If
  End If

  Return nextLink
End Function

Function getEventStartDate( id )
  Define
    id      Integer,
    dtStart Date

  Try
    Select datestart
      Into dtStart
      From events
     Where events.eventid = id
  Catch
    Display "SQL Select date start Error: ",Sqlca.sqlcode," ",SqlErrMessage
  End Try

  Return dtStart
End Function

Function selectEvent( id )
  Define
    id      Integer,
    dbEvent tDbEvent

  Select *
    Into dbEvent.*
    From events
   Where events.eventid = id

  Return dbEvent.*
End Function

Function connectDb()
  Connect To ":memory:+driver='dbmsqt'"

  Create Table users (
    userid    Integer,
    firstname Char(20),
    lastname  Char(20)
    )
  Insert Into users Values (1,"Joe","Doe")
  Insert Into users Values (2,"Jim","Ask")
  Insert Into users Values (3,"Luc","Sky")

  Create Table events (
    eventId      Integer,
    userId       Integer,
    dateStart    Date,
    hourStart    DateTime Hour To Second,
    dateEnd      Date,
    hourEnd      DateTime Hour To Second,
    recurrence   Smallint,
    repeattill   Date,
    repmonday    Boolean,
    reptuesday   Boolean,
    repwednesday Boolean,
    repthursday  Boolean,
    repfriday    Boolean,
    repsaturday  Boolean,
    repsunday    Boolean,
    eventTitle   Char(50),
    eventDesc    Char(200),
    eventParent  Integer
    )
  Insert Into events Values (1,1,Today,"09:30:00",Today,"10:00:00",0,Null,False,False,False,False,False,False,False,"Conference Call","FF91 Project",0)
  Insert Into events Values (2,1,Today,"10:30:00",Today,"11:00:00",0,Null,False,False,False,False,False,False,False,"Daily Scrum","FF91 Project",0)
  Insert Into events Values (3,2,Today,"09:45:00",Today,"10:45:00",0,Null,False,False,False,False,False,False,False,"Web Site Design Plan","Beauty is in the eyes of the beholder",0)
End Function