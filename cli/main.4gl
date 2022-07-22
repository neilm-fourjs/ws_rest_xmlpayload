IMPORT util
IMPORT xml
IMPORT FGL ex1

TYPE t_rec RECORD
	test        STRING ATTRIBUTE(XMLAttribute, XMLOptional),
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
	xml STRING ATTRIBUTE(XMLOptional)
END RECORD

MAIN
	DEFINE l_ret     SMALLINT
	DEFINE l_reply   STRING
	DEFINE l_xml_doc xml.DomDocument
	DEFINE l_xml     xml.DomNode
	DEFINE l_rec     t_rec ATTRIBUTE(XMLName = "info")
	DEFINE l_rec2    t_rec ATTRIBUTE(XMLName = "info")

	CALL ex1.status() RETURNING l_ret, l_reply
	DISPLAY SFMT("Ret: %1 Reply: %2", l_ret, l_reply)

	CALL ex1.info("test") RETURNING l_ret, l_reply
	DISPLAY SFMT("Ret: %1 Reply: %2", l_ret, l_reply)

	DISPLAY "Serialize JSON to 4gl"
	TRY
		CALL util.JSON.parse(l_reply, l_rec)
	CATCH
		DISPLAY SFMT("Failed! %1:%2", STATUS, sqlca.sqlerrm)
		EXIT PROGRAM
	END TRY

	DISPLAY SFMT("JSON Server: %1 Genero: %2", l_rec.server, l_rec.genero_ver)

  IF l_rec.xml IS NULL THEN
    DISPLAY "No XML"
    EXIT PROGRAM
  END IF

	LET l_xml_doc = xml.DomDocument.Create()
	DISPLAY "Load XML string into XML domDocument"
	TRY
		CALL l_xml_doc.loadFromString(l_rec.xml)
		LET l_xml = l_xml_doc.getDocumentElement()
	CATCH
		DISPLAY SFMT("Failed! %1:%2", STATUS, sqlca.sqlerrm)
		EXIT PROGRAM
	END TRY

--	CALL l_xml_doc.setFeature("format-pretty-print", TRUE)
--	DISPLAY l_xml_doc.saveToString()

	DISPLAY "Serialize XML to 4gl"
	TRY
		CALL xml.Serializer.DomToVariable(l_xml, l_rec2)
	CATCH
		DISPLAY SFMT("Failed! %1:%2", STATUS, sqlca.sqlerrm)
		EXIT PROGRAM
	END TRY

	DISPLAY SFMT("XML Server: %1 test: %2", l_rec2.server, l_rec2.test)

END MAIN
