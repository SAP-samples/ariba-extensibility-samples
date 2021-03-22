import java.util.HashMap;
import groovy.json.*

import com.sap.gateway.ip.core.customdev.util.Message;
import com.sap.it.api.asdk.runtime.*


def Message setAribaDateFilter(Message message) {
    def messageLog = messageLogFactory.getMessageLog(message)
    
    //Get Headers 
    def map = message.getHeaders();
    def updatedDateFrom = map.get("updatedDateFrom")
    def updatedDateTo = map.get("updatedDateTo")

    def dateFrom = "updatedDateFrom"
    def dateTo = "updatedDateTo"
    
    // Set the value for filters query parameter
    if(updatedDateFrom != "" && updatedDateTo != "") {
        message.setHeader("dateFilter", '{"' + dateFrom + '":"'+ updatedDateFrom + '","' + dateTo + '":"'+ updatedDateTo + '"}')
    } else {
        def dates = calculateDates(map.get("dateInterval", 60) as int)
        
        def dateFilter = '{"' + dateFrom + '":"' + convertDateToAribaStringFormat(dates[0]) + '","' + dateTo + '":"' + convertDateToAribaStringFormat(dates[1]) + '"}'
        
        message.setHeader("dateFilter", dateFilter)
        messageLog.setStringProperty("dateFilter", dateFilter)
    }
       
    return message
}

def Tuple calculateDates(interval){
    def dateTo = new Date()
    def dateFrom = new Date()
    
    def minutes = dateTo.minutes
    
    // Calculate the dateTo based on the interval   
    dateTo.putAt(Calendar.MINUTE, minutes - (minutes % interval))
    dateTo.putAt(Calendar.SECOND, 0)
    
    use (groovy.time.TimeCategory) {
        dateFrom = dateTo - interval.minutes
    }
    
    return new Tuple(dateFrom, dateTo)
}

def convertDateToAribaStringFormat(date) {
    return date.format('yyyy-MM-dd HH:mm:ss').replace(" ", "T") + "Z"
}


def Message processAribaResponse(Message message) {

    def messageLog = messageLogFactory.getMessageLog(message)

    //Body
    def body = message.getBody(String);
    
    // Convert payload to JSON object
    def jsonSlurper = new JsonSlurper()
    def object = jsonSlurper.parseText(body)

    if(!("Records" in object) || object.Records == []) {
        // No elements to process
        message.setHeader("pageToken", "STOP");
        message.setProperty("entryId", "Response");
        
    } else {
        
        // Retrieving PageToken from payload if one exists
        if("PageToken" in object) {
            messageLog.setStringProperty("PageToken", object.PageToken);
            message.setHeader("pageToken", object.PageToken);
            message.setProperty("entryId", "Response_" + object.PageToken);
        } else {
            messageLog.setStringProperty("PageToken", "NONE!");
            message.setHeader("pageToken", "STOP");
            message.setProperty("entryId", "Response");
        }
    }

    return message;
}

/**
 * Data transformation methods
 */

def String convertToSAPDate(val) {
    return val.substring(0,10).replaceAll('-','')
}

def String convertToSAPTime(val) {
    return val.substring(11,19).replaceAll(':','')
}

def Tuple convertToSAPDateTime(val) {
    def date = convertToSAPDate(val)
    def time = convertToSAPTime(val)
    
    return new Tuple(date, time)
}