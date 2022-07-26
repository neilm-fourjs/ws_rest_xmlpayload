IMPORT FGL logging
IMPORT FGL ws_lib
IMPORT util
IMPORT os
IMPORT xml

CONSTANT C_VER = "1.0"

--------------------------------------------------------------------------------------
-- Return the status of the service
PUBLIC FUNCTION status() ATTRIBUTES(WSGet, WSPath = "/status", WSDescription = "Returns status of service")
		RETURNS STRING
	CALL logging.logIt("status", "Doing Status checks.")
	RETURN "Okay"
END FUNCTION
--------------------------------------------------------------------------------------
-- Return server info
PUBLIC FUNCTION info(l_db STRING ATTRIBUTE(WSQuery, WSOptional, WSName = "db"))
		ATTRIBUTES(WSGet, WSPath = "/info", WSDescription = "Returns information about server") RETURNS STRING
	DEFINE l_ret RECORD ATTRIBUTE(XMLName = "info")
		server      STRING,
		os_ver      STRING,
		pid         STRING,
		service_ver STRING,
		statDesc    STRING,
		server_date DATE,
		server_time DATETIME HOUR TO SECOND,
		lang        STRING,
		genero_ver  STRING,
		db_info RECORD
			def_dbdriver STRING,
			db_driver    STRING,
			db_date      STRING,
			db_name      STRING ATTRIBUTE(XMLNillable),
			db_status    STRING ATTRIBUTE(XMLOptional)
		END RECORD,
		env DYNAMIC ARRAY ATTRIBUTE(XMLList) OF RECORD
			name  STRING,
			value STRING
		END RECORD,
		xml STRING
	END RECORD
	DEFINE c         base.Channel
	DEFINE i         SMALLINT = 0
	DEFINE x         SMALLINT
	DEFINE l_os      STRING
	DEFINE l_line    STRING
	DEFINE l_xml_doc xml.DomDocument
	DEFINE l_xml     xml.DomNode

	LET l_ret.pid         = fgl_getPID()
	LET l_ret.server      = fgl_getEnv("HOSTNAME")
	LET l_ret.service_ver = C_VER
	LET l_ret.lang        = fgl_getEnv("LANG")
	IF l_ret.server IS NULL THEN
		LET c = base.Channel.create()
		CALL c.openPipe("hostname -f", "r")
		LET l_ret.server = c.readLine()
		CALL c.close()
	END IF
	IF os.Path.exists("/etc/issue") THEN
		LET l_os = "/etc/issue"
	END IF
	IF os.Path.exists("/etc/redhat-release") THEN
		LET l_os = "/etc/redhat-release"
	END IF
	IF l_os IS NOT NULL THEN
		LET c = base.Channel.create()
		CALL c.openFile(l_os, "r")
		LET l_ret.os_ver = c.readLine()
		CALL c.close()
	END IF

	LET l_ret.genero_ver = fgl_getVersion()

	LET l_ret.server_date = TODAY
	LET l_ret.server_time = CURRENT
	LET l_ret.statDesc    = "Okay"

	CALL logging.logIt("info", SFMT("Returning information db='%1'.", l_db))

	RUN SFMT("env | sort > %1.env", l_ret.pid) -- debug only
	LET c = base.Channel.create()
	CALL c.openPipe("env", "r")
	WHILE NOT c.isEof()
		LET l_line = c.readLine()
		IF l_line IS NOT NULL THEN
			LET x                          = l_line.getIndexOf("=", 1)
			LET l_ret.env[i := i + 1].name = l_line.subString(1, x - 1)
			LET l_ret.env[i].value         = l_line.subString(x + 1, l_line.getLength())
			{IF l_ret.env[i].name = "PS1" THEN -- avoid escape chars breaking the XML!
				LET l_ret.env[i].value = "..."
			END IF}
		END IF
	END WHILE
	CALL c.close()
	CALL l_ret.env.sort("name", FALSE)

	LET l_ret.db_info.def_dbdriver = base.Application.getResourceEntry("dbi.default.driver")
	IF l_ret.db_info.def_dbdriver IS NULL THEN
		LET l_ret.db_info.def_dbdriver = "dbmdefault"
	END IF
	LET l_ret.db_info.db_date = fgl_getEnv("DBDATE")
	LET l_ret.db_info.db_name = "No Database Name"
	IF l_db IS NOT NULL THEN
		LET l_ret.db_info.db_driver = base.Application.getResourceEntry(SFMT("dbi.%1.driver", l_db))
		IF l_ret.db_info.db_driver IS NULL THEN
			LET l_ret.db_info.db_driver = "Not defined in fglprofile"
		END IF

		LET l_ret.db_info.db_name = l_db
		TRY
			DATABASE l_db
			LET l_ret.db_info.db_status = "Okay"
		CATCH
			LET l_ret.db_info.db_status = SQLERRMESSAGE
		END TRY
	END IF

-- Create the XML doc
	LET l_xml_doc = xml.DomDocument.Create()
-- Create the XML node
	LET l_xml = l_xml_doc.createElement("info")
-- Load the data from l_ret into the xml node
	CALL xml.Serializer.VariableToDom(l_ret, l_xml)
-- I get firstChild because I don't want the 'root' node
	LET l_xml = l_xml.getFirstChild()
-- Set a test attribute just to show that attributes work
	CALL l_xml.setAttribute("test", "This is a test")

-- display XML debug!
--  CALL l_xml_doc.setFeature("format-pretty-print", TRUE)
	CALL l_xml_doc.appendDocumentNode(l_xml)
{	TRY -- If I do this then I get the expected errors - if I don't then the later error count doesnt work!
		DISPLAY l_xml_doc.saveToString()
	CATCH
		DISPLAY SFMT("Failed: %1 %2 Errors: %3", STATUS, SQLCA.sqlerrm, l_xml_doc.getErrorsCount())
		FOR i = 1 TO l_xml_doc.getErrorsCount()
			DISPLAY SFMT("Error #%1 %2", i, l_xml_doc.getErrorDescription(i))
		END FOR
	END TRY}

-- put the xml into the record
	IF l_xml IS NOT NULL THEN
		TRY
			LET l_ret.xml = l_xml.toString()
		CATCH
			DISPLAY SFMT("Failed: %1 %2 Errors: %3", STATUS, SQLCA.sqlerrm, l_xml_doc.getErrorsCount())
			FOR i = 1 TO l_xml_doc.getErrorsCount()
				DISPLAY SFMT("Error #%1 %2", i, l_xml_doc.getErrorDescription(i))
			END FOR
		END TRY
	ELSE
		DISPLAY "XML is NULL!"
	END IF

-- return the record as a JSON STRING
	RETURN util.JSON.stringify(l_ret)
END FUNCTION
----------------------------------------------------------------------------------------------------
-- Just exit the service
FUNCTION exit() ATTRIBUTES(WSGet, WSPath = "/exit", WSDescription = "Exit the service") RETURNS STRING
	CALL logging.logIt("exit", "Stopping service.")
	LET ws_lib.m_stop = TRUE
	RETURN "Stopped"
END FUNCTION
