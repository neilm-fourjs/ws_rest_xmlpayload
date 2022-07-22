IMPORT FGL ws_lib
IMPORT FGL logging
IMPORT FGL ws_rest_ex
MAIN

	CALL logging.logIt("MAIN", "Started")

	IF NOT ws_lib.init("ws_rest_ex", "ex1") THEN
		EXIT PROGRAM
	END IF

	CALL ws_lib.process()

	CALL logging.logIt("MAIN", "Finished")
END MAIN
