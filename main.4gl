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
    eventTitle    Char(50),
    eventDesc     Char(200),
    eventParent   Integer
                End Record

Main
  Define
    dateStart  Date,
    dateEnd    Date,
    hourEnd    DateTime Hour To Second,
    wEvent     calendar.tEvent,
    retCod     Integer

  -- Database used is Sqlite with in-memory feature
  -- DB definition can be found at the bottom of this file.
  Call connectDb()

  Close Window Screen

  Open Window wAgenda With Form "agenda"

    Call calendar.init()
    Call initUsers()
    Call initEvents()

    Dialog Attributes (Unbuffered)
      SubDialog calendar.dlgCalendar

      On Action new
        Let calendar.currentEventRowNo = calendar.displayEventDetails(0)
        Call calendar.readWcEvent(calendar.calendarPipe) Returning wEvent.*
        Call calendar.completeEvent(wEvent.*)
          Returning retCod,calendar.currentEventRowNo,wEvent.*
        If retCod Then
          Let wEvent.id = getNewEvenId()
          Let dateStart = wEvent.start
          Let dateEnd   = wEvent.end
          If dateEnd > dateStart Then
            Let wEvent.eventParent = wEvent.id
            Let hourEnd = wEvent.end
            Let wEvent.end = calendar.formatWcDateHour(DateStart,HourEnd)
          Else
            Let wEvent.eventParent = 0
          End If
          For retCod=0 To dateEnd-dateStart
            If insertDbEvent(wEvent.*) Then
              Let calendar.currentEventRowNo = calendar.addEvent(wEvent.id,
                                 wEvent.userId,
                                 wEvent.start,
                                 wEvent.end,
                                 wEvent.title,
                                 wEvent.eventDesc,
                                 wEvent.eventParent)
            End If
            Let wEvent.eventParent = wEvent.id
            Let wEvent.id = getNewEvenId()
            Let wEvent.start = wEvent.start + Interval( 1 ) Day To Day
            Let wEvent.end = wEvent.end + Interval( 1 ) Day To Day
          End For
        End If
        Call calendar.refreshEvents()

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
        End If

      On Action close
        Exit Dialog
    End Dialog

  Close Window wAgenda
End Main

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
Function modifyEvent( wEvent )
  Define
    wEvent     calendar.tEvent,
    dateStart  Date,
    dateEnd    Date,
    hourEnd    DateTime Hour To Second,
    dbEvent    tDbEvent,
    retCod     Integer

  Let dateStart = wEvent.start
  Let dateEnd   = wEvent.end
  If dateEnd > dateStart Then
    Let wEvent.eventParent = wEvent.id
    Let hourEnd = wEvent.end
    Let wEvent.end = calendar.formatWcDateHour(dateStart,hourEnd)
  Else
    Let wEvent.eventParent = 0
  End If
  -- Update existing chaine
  While dateEnd >= dateStart
    Let hourEnd = wEvent.end
    Let wEvent.end = calendar.formatWcDateHour(dateStart,hourEnd)
    Let retCod = updateEvent( wEvent.* )
    Let wEvent.eventParent = wEvent.id
    Let wEvent.start = wEvent.start + Interval( 1 ) Day To Day
    Let wEvent.end = wEvent.end + Interval( 1 ) Day To Day
    Let wEvent.id = getEventNextLink( wEvent.id )
    Let dateStart = wEvent.start
    If wEvent.id = 0 Then
      Exit While
    End If
  End While
  -- Create new link if needed
  While dateEnd >= dateStart
    Let wEvent.id = getNewEvenId()
    If insertDbEvent(wEvent.*) Then
      Let calendar.currentEventRowNo = calendar.addEvent(wEvent.id,
                               wEvent.userId,
                               wEvent.start,
                               wEvent.end,
                               wEvent.title,
                               wEvent.eventDesc,
                               wEvent.eventParent)
    End If
    Let wEvent.eventParent = wEvent.id
    Let wEvent.start = wEvent.start + Interval( 1 ) Day To Day
    Let wEvent.end = wEvent.end + Interval( 1 ) Day To Day
    Let dateStart = wEvent.start
    If dateEnd < dateStart Then
      Let wEvent.id = 0
    End If
  End While
  -- Trim right chaine
  While wEvent.id <> 0
    Let retCod = removeEvent( wEvent.id )
    Let wEvent.id = getEventNextLink( wEvent.Id )
  End While
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
    Call calendar.updateWcEvent( pos,
                     wEvent.id,
                     wEvent.userId,
                     wEvent.start,
                     wEvent.end,
                     wEvent.title,
                     wEvent.eventDesc,
                     wEvent.eventParent)
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
  Declare cEvents Cursor From "Select eventid,userid,datestart,hourstart,dateend,hourend,eventtitle,eventdesc,eventparent From events Order By eventid"
  Foreach cEvents Into dbEvent.*
    Let pos = calendar.addEvent(dbEvent.eventId,
                              dbEvent.userId,
                              calendar.formatWcDateHour(dbEvent.dateStart,dbEvent.hourStart),
                              calendar.formatWcDateHour(dbEvent.dateEnd,dbEvent.hourEnd),
                              dbEvent.eventTitle,
                              dbEvent.eventDesc,
                              dbEvent.eventParent)
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
    Insert Into events
      (eventId,
       userId,
       dateStart,
       hourStart,
       dateEnd,
       hourEnd,
       eventTitle,
       eventDesc,
       eventParent
      ) Values (
       dbEvent.eventId,
       dbEvent.userId,
       dbEvent.dateStart,
       dbEvent.hourStart,
       dbEvent.dateEnd,
       dbEvent.hourEnd,
       dbEvent.eventTitle,
       dbEvent.eventDesc,
       dbEvent.eventParent)
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

  Select eventid,userid,datestart,hourstart,dateend,hourend,eventtitle,eventdesc,eventparent
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
  Insert Into users Values (1,"Jérémi","Quellebronn")
  Insert Into users Values (2,"Georges","Lucas")
  Insert Into users Values (3,"Stephen","King")

  Create Table events (
    eventId      Integer,
    userId       Integer,
    dateStart    Date,
    hourStart    DateTime Hour To Second,
    dateEnd      Date,
    hourEnd      DateTime Hour To Second,
    eventTitle   Char(50),
    eventDesc    Char(200),
    eventParent  Integer
    )
  Insert Into events Values (1,1,Today,"09:30:00",Today,"10:00:00","Conference Call","FF91 Project",0)
  Insert Into events Values (2,1,Today,"10:30:00",Today,"11:00:00","Daily Scrum","FF91 Project",0)
  Insert Into events Values (3,2,Today,"09:45:00",Today,"10:45:00","Web Site Design Plan","Beauty is in the eyes of the beholder",0)
End Function