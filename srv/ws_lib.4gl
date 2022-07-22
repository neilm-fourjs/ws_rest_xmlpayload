IMPORT com
IMPORT FGL logging

PUBLIC DEFINE m_stop BOOLEAN = FALSE

DEFINE m_service      STRING
DEFINE m_service_desc STRING
----------------------------------------------------------------------------------------------------
-- Initialize the service - Start the log and connect to database.
FUNCTION init(l_service STRING, l_service_desc STRING) RETURNS BOOLEAN
	LET m_service      = l_service
	LET m_service_desc = l_service_desc
	CALL logging.logIt("init", SFMT("Server: %1", m_service))
	RETURN TRUE
END FUNCTION
----------------------------------------------------------------------------------------------------
-- Start the service loop
FUNCTION process()
	DEFINE l_ret SMALLINT
	DEFINE l_msg STRING

	CALL com.WebServiceEngine.RegisterRestService(m_service, m_service_desc)

	LET l_msg = SFMT("Service '%1' started.", m_service)
	CALL com.WebServiceEngine.Start()
	WHILE TRUE
		CALL logging.logIt("process", l_msg)
		LET l_ret = com.WebServiceEngine.ProcessServices(-1)
		CASE l_ret
			WHEN 0
				LET l_msg = "Request processed."
			WHEN -1
				LET l_msg = "Timeout reached."
			WHEN -2
				LET l_msg = "Disconnected from application server."
				EXIT WHILE # The Application server has closed the connection
			WHEN -3
				LET l_msg = "Client Connection lost."
			WHEN -4
				LET l_msg = "Server interrupted with Ctrl-C."
			WHEN -8
				LET l_msg = "Internal HTTP Error."
			WHEN -9
				LET l_msg = "Unsupported operation."
			WHEN -10
				LET l_msg = "Internal server error."
			WHEN -23
				LET l_msg = "Deserialization error."
			WHEN -35
				LET l_msg = "No such REST operation found."
			WHEN -36
				LET l_msg = "Missing REST parameter."
			WHEN -40
				LET l_msg = "Missing Scope."
			OTHERWISE
				LET l_msg = SFMT("Unexpected server error %1.", l_ret)
				EXIT WHILE
		END CASE
		IF int_flag != 0 THEN
			LET l_msg    = "Service interrupted."
			LET int_flag = 0
			EXIT WHILE
		END IF
		IF m_stop THEN
			EXIT WHILE
		END IF
	END WHILE
	CALL logging.logIt("process", "Server stopped.")

END FUNCTION
