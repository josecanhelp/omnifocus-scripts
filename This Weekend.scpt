(*
	# DESCRIPTION #
	
	This script takes the currently selected actions or projects and sets them to start and finish on the coming weekend. (If a weekend is currently in progress, the items will be set for the current weekend.)
	
	The dates and times are set by variables, so you can modify to meet your weekend.
	
	# LICENSE #

	Copyright © 2010 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	

	# CHANGE HISTORY #

	0.1c (2010-06-22)
		-	Actual fix for autosave

	0.1b (2010-06-21)
		-	Encapsulated autosave in "try" statements in case this fails

	0.1: Initial release. Based on my Defer script, which incorporates bug fixes from Curt Clifton. By default, notifications are disabled (uncomment the appropriate lines to enable them).


	# INSTALLATION #

	1. Copy to ~/Library/Scripts/Applications/Omnifocus
 	2. If desired, add to the OmniFocus toolbar using View > Customize Toolbar... within OmniFocus

	# KNOWN BUGS #
	
	- When the script is invoked from the OmniFocus toolbar and canceled, OmniFocus returns an error. This issue does not occur when invoked from the script menu, a Quicksilver trigger, etc.
		
*)

-- To change your weekend start/stop date/time, modify the following properties
property weStartDay : Friday
property weStartTime : 20 --due time in hrs (24 hr clock)
property weEndDay : Sunday
property weEndTime : 17 --due time in hours (24 hr clock)

--To enable alerts, change these settings to True _and_ uncomment
property showAlert : false --if true, will display success/failure alerts
property useGrowl : true --if true, will use Growl for success/failure alerts

-- Don't change these
property alertItemNum : ""
property alertDayNum : ""
property dueDate : ""
property growlAppName : "Dan's Scripts"
property allNotifications : {"General", "Error"}
property enabledNotifications : {"General", "Error"}
property iconApplication : "OmniFocus.app"

tell application "OmniFocus"
	tell front document
		tell (first document window whose index is 1)
			set theSelectedItems to selected trees of content
			set numItems to (count items of theSelectedItems)
			if numItems is 0 then
				my notify("Error", "Script failure", "No valid task(s) selected")
				return
			end if
			
			--Calculate due date
			set dueDate to current date
			set theTime to time of dueDate
			repeat while weekday of dueDate is not weEndDay
				set dueDate to dueDate + 1 * days
			end repeat
			set dueDate to dueDate - theTime + weEndTime * hours
			--set dueDate to dueDate + 1 * weeks --uncomment to use _next_ weekend instead
			
			--Calculate start date
			set diff to weEndDay - weStartDay
			if diff < 0 then set diff to diff + 7
			set diff to diff * days + (weEndTime - weStartTime) * hours
			set startDate to dueDate - diff
			
			--Perform action
			set selectNum to numItems
			set successTot to 0
			set autosave to false
			repeat while selectNum > 0
				set selectedItem to value of item selectNum of theSelectedItems
				set succeeded to my changeDate(selectedItem, startDate, dueDate)
				if succeeded then set successTot to successTot + 1
				set selectNum to selectNum - 1
			end repeat
			set autosave to true
			
			--Set up alert according to preferences
			if successTot > 1 then set alertItemNum to "s"
			set alertText to successTot & " item" & alertItemNum & " now due this weekend." as string
		end tell
	end tell
	my notify("General", "Script complete", alertText)
end tell

on changeDate(selectedItem, startDate, dueDate)
	set success to false
	tell application "OmniFocus"
		try
			set start date of selectedItem to startDate
			set due date of selectedItem to dueDate
			set success to true
		end try
	end tell
	return {success}
end changeDate

on notify(alertName, alertTitle, alertText)
	if showAlert is false then
		return
	else if useGrowl is true then
		--check to make sure Growl is running
		tell application "System Events" to set GrowlRunning to ((application processes whose (name is equal to "GrowlHelperApp")) count)
		if GrowlRunning = 0 then
			--try to activate Growl
			try
				do shell script "/Library/PreferencePanes/Growl.prefPane/Contents/Resources/GrowlHelperApp.app/Contents/MacOS/GrowlHelperApp > /dev/null 2>&1 &"
				do shell script "~/Library/PreferencePanes/Growl.prefPane/Contents/Resources/GrowlHelperApp.app/Contents/MacOS/GrowlHelperApp > /dev/null 2>&1 &"
			end try
			delay 0.2
			tell application "System Events" to set GrowlRunning to ((application processes whose (name is equal to "GrowlHelperApp")) count)
		end if
		--notify
		if GrowlRunning ≥ 1 then
			try
				tell application "GrowlHelperApp"
					register as application growlAppName all notifications allNotifications default notifications allNotifications icon of application iconApplication
					notify with name alertName title alertTitle application name growlAppName description alertText
				end tell
			end try
		else
			set alertText to alertText & " 
 
p.s. Don't worry—the Growl notification failed but the script was successful."
			display dialog alertText with icon 1
		end if
	else
		display dialog alertText with icon 1
	end if
end notify