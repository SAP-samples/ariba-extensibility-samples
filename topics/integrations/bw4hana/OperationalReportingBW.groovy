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


def Message exchangeDSOPropertyAndBody(Message message) {
    def messageLog = messageLogFactory.getMessageLog(message)
    
    //Body
    def body = message.getBody(String);
    
    // Current DSO to process
    def DSO = body.split()[1].trim()
    
    // Header required for dynamic BW URL
    message.setHeader("DSO", DSO)
    
    def props = message.getProperties()
    
    // Extract the DSO specific body
    def payload = props.get(DSO)
    
    message.setBody(payload)
    
    return message
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
    } else {
        
        // Retrieving PageToken from payload if one exists
        if("PageToken" in object) {
            messageLog.setStringProperty("PageToken", object.PageToken);
            message.setHeader("pageToken", object.PageToken);
        } else {
            messageLog.setStringProperty("PageToken", "NONE!");
            message.setHeader("pageToken", "STOP");
        }
    
        def props = message.getProperties()
        
        def documentType = props.get('Ariba_DocumentType')
    
        // Condition to handle multiple document types
        if (documentType == 'SourcingRequestFact') {
            message = transformSourcingRequest(message, object)
        } else if (documentType == 'ProjectInfoDim') {
            message = transformProjectInfo(message, object)
        } 
    }

    return message;
}

def transformSourcingRequest(message, object) {
    def processDSOs = '''DSO
Z_ARB01
Z_ARB02'''

    def builder = new JsonBuilder()

    /**
    * Objects to insert in BW
    */
    def projects = [] // Z_ARB01
    def commodities = [] // Z_ARB02
    
    // Process all records in Payload
    object.Records.collect { record ->

        def ProjectId = record.ProjectId
        def ProjectSourceSystem = record.SourceSystem.SourceSystemId
        def dtCreated = convertToSAPDateTime(record.TimeCreated)
        def dtUpdated = convertToSAPDateTime(record.TimeUpdated)

        // Build JSON payload
        builder IS_TEST_PROJECT: record.IsTestProject,
        ORIGIN: record.Origin,
        OWNER_SOURCE_SYSTEM: record.Owner.SourceSystem,
        OWNER_USER_ID: record.Owner.UserId,
        DESCRIPTION: record.Description,
        PROCESS_STATUS: record.ProcessStatus,
        ONTIME_OR_LATE: record.OnTimeOrLate,
        CONTAINER_PROJECT_ID: record.ContainerProject.ProjectId,
        CONTAINER_SOURCE_SYSTEM: record.ContainerProject.SourceSystem,
        PROJECT_ID: ProjectId,
        SOURCE_SYSTEM: ProjectSourceSystem,
        STATUS: record.Status,
        TIME_CREATED: dtCreated[1],
        DATE_CREATED: dtCreated[0],
        TIME_UPDATED: dtUpdated[1],
        DATE_UPDATED: dtUpdated[0]

        projects << builder.content
        
        /**
        * Process nested structures
        */
        commodities = commodities.plus(processCommodities(ProjectId, ProjectSourceSystem, record.Commodity))
    }

    message.setBody(processDSOs);
    
    message.setProperty("ZCM_ARB01", JsonOutput.toJson(projects));
    message.setProperty("ZCM_ARB02", JsonOutput.toJson(commodities));
    
    return message
}


def transformProjectInfo(message, object) {
    def processDSOs = '''DSO
Z_ARB03
'''

    def builder = new JsonBuilder()

    /**
    * Objects to insert in BW
    */
    def projects = [] // Z_ARB03
    
    object.Records.collect { record ->

        def projectId = record.ProjectId
        def projectSourceSystem = record.SourceSystem
        
        def dtCreated = convertToSAPDateTime(record.TimeCreated)
        def dtUpdated = convertToSAPDateTime(record.TimeUpdated)

        builder PROJECT_TYPE_NAME: record.ProjectTypeName,
        PROJECT_NAME: record.ProjectName,
        PROJECT_TYPE_ID: record.ProjectTypeId,
        TEMPLATE_NAME: record.TemplateName,
        PROJECT_ID: projectId,
        SOURCE_SYSTEM: projectSourceSystem,
        TIME_CREATED: dtCreated[1],
        DATE_CREATED: dtCreated[0],
        TIME_UPDATED: dtUpdated[1],
        DATE_UPDATED: dtUpdated[0]
        
        projects << builder.content
        
    }

    message.setBody(processDSOs);
    
    message.setProperty("Z_ARB03", JsonOutput.toJson(projects));
    
    return message
}

/**
 * Process the Commodity structure
 *
 */
def List processCommodities(projectId, sourceSystem, arr){
    def builder = new JsonBuilder()
    def commodities = []

    arr.each {
        builder PROJECT_ID: projectId,
        SOURCE_SYSTEM: sourceSystem,
        COMMODITY_ID: it.Commodity.CommodityId,
        SOURCE_COMMODITY_DOMAIN: it.Commodity.SourceCommodityDomain

        commodities << builder.content
    }

    return commodities
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
