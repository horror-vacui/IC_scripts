; zoltan.tibenszky@tu-dredsen.de
; v0.1:  2017-06-12
; v0.2:  2017-09-28 - Extending functionality with fill script
; v0.2a: 2017-10-10 - Resetted the control bits DO_xxx after run, to avoid problems with manual stream-out callback.
;
; To do ideas:
;	- Create a window, with radio buttons where the different options could be selected
;		* A debug mode could have been added as well
;	- The backup of "layout" cellview's name would contain the date


DEBUG			 = nil  ; nir ot t
IS_MENU 		 = t
IS_STRM_CALLBACK = t	; the fill script will be called after the strmout

TECH_LIB        = "cmos22fdsoi"
WORK_DIR        = strcat(getShellEnvVar("ICPRO_TMP") "/FILL")
DIR_TECHMAP     = strcat(getShellEnvVar("PDK_HOME") "/DesignEnv/VirtuosoOA/libs/cmos22fdsoi_tech_9M_2Mx_5Cx_1Jx_1Ox_LB")
FILL_LIB_SUFFIX = "_fill"
LAYERMAP        = strcat(DIR_TECHMAP "/cmos22fdsoi_tech.layermap")
OBJECTMAP       = strcat(DIR_TECHMAP "/cmos22fdsoi_tech.objectmap")
FILL_PDK_DIR    = strcat(getShellEnvVar("PDK_HOME") "/FILLGEN/Calibre")
MY_DF2_DIR	    = getWorkingDir()  ; assumes that it will be loaded at Cadence startup
LIB_NAME	    = ""
CELL_NAME       = ""
VIEW_NAME       = ""
FILL_LIB_NAME   = ""
FILL_SETUP      = "cfill.setup" 
COLOR_SETUP     = "cfill.rebal.setup" 
DO_FILL    		= nil  
DO_TOP 			= nil
DO_COLOR		= nil

; if work directory is not present, create it!
unless( isDir(WORK_DIR)   system(strcat("mkdir " WORK_DIR))   )

procedure( get_cell_data()
	CELL_NAME     = hiGetCurrentWindow()~>topCellView~>cellName
	LIB_NAME      = hiGetCurrentWindow()~>topCellView~>libName
	VIEW_NAME     = hiGetCurrentWindow()~>topCellView~>viewName
	GDS_OUT       = strcat(WORK_DIR "/" CELL_NAME "_" VIEW_NAME ".gds")
	FILL_LIB_NAME = strcat(LIB_NAME "_fill")
)

procedure( streamout()  ; uses global variables for the stream-out
	when(LIB_NAME=="" || CELL_NAME=="" || VIEW_NAME==""
		get_cell_data()
	)
	xstSetField("strmFile"  GDS_OUT   )
	xstSetField("library"   LIB_NAME  )
	xstSetField("topCell"   CELL_NAME )
	xstSetField("view"      VIEW_NAME )
	xstSetField("objectMap" OBJECTMAP )
	xstSetField("layerMap"  LAYERMAP  )
	xstSetField("runDir" 	WORK_DIR  )
	xstSetField("outputDir" WORK_DIR  )
	xstSetField("enableColoring" "true"  )
	xstSetField("logFile"   strcat(LIB_NAME "_" CELL_NAME "_" VIEW_NAME "_out.log")  )
	if( DEBUG then
		xstSetField("showCompletionMsgBox" "true"  )
	else
		xstSetField("showCompletionMsgBox" "false"  )
	) ;if
	println("Call xstDoTranslate")
	xstOutDoTranslate()
)
if(IS_STRM_CALLBACK then
	procedure(xstOutOnCompletion(status) 
	prog( ( )
		printf("In xstOutOnCompletion of XStream Out GUI: %d\n" status)
		if( status == 0 then
			printf("Successfully completed\n" status)
			if( DO_FILL || DO_COLOR then 
				println("Fill and coloring to be started.")	
				zti_run_fill_script( ?do_fill DO_FILL ?do_color DO_COLOR ) 
			)
		else
			println("Error occured during translation\n" status)
		);if	
	);prog
	) ; xstOutOnCompletion
) ; if

; checking whether a file needed for the fill script is already present in WORK_DIR and if not, copies it from the PDK
procedure( check_fill_file(filename)
let( (cmd local_file pdk_file)
	local_file = strcat(WORK_DIR "/" filename)
	printf("Checking file %s.\n" local_file)
	unless(isFile(local_file)
		printf("Local file %s is not found." local_file)
		pdk_file = strcat(FILL_PDK_DIR "/" filename)
		if(isFile(pdk_file)
			then
				cmd=strcat("cp " pdk_file " " local_file)
				printf("Copying the pdk file (%s) into the working directory (%s).\n" pdk_file WORK_DIR)
				system(cmd)
			else
				error("No pdk file has been found! The local version is expected be at %s, while the PDK version at %s" local_file pdk_file)
		);if
	);unless
)) ; check_fill_file

procedure( streamin( @key (is_completion_box nil) (gds_suffix ".swap.gds") )
let( (msgbox gds_fname (FILL_LIB_LOCATION strcat(ddGetObj(LIB_NAME)~>readPath FILL_LIB_SUFFIX))   )
	; Create fill library if it does not exixst already
	; We need to be at the DF2 directory to do that.
;	changeWorkingDir(MY_DF2_DIR)
;	printf("%s\n" FILL_LIB_LOCATION)
	unless(ddGetObj(FILL_LIB_NAME) ; If the design library does not exists (=not in Lib Mgr)
	let( (desLib)
		unless(isDir(FILL_LIB_LOCATION) createDir(FILL_LIB_LOCATION)  )  ; If the directory does not exists
		desLib=ddCreateLib(FILL_LIB_NAME FILL_LIB_LOCATION)
		techBindTechFile(desLib TECH_LIB)  ; Attach a techlib to it
		unless(desLib
			error("could not create library")
		)
	))
;	changeWorkingDir(WORK_DIR)

	; Set the parameters for Stream-In
	; xstInSetField("strmFile"  strcat(WORK_DIR "/" CELL_NAME "_" VIEW_NAME ".filled.gds"))
	; .fill.gds contains only the BEOL fill. The FEOL fill is added by using "markers".
	; To import all FILL back we need to use the .swap.gds output. 
	gds_fname=strcat(WORK_DIR "/" CELL_NAME "_" VIEW_NAME gds_suffix)
	if(isFile(gds_fname) then println("The gds file to import exists.")
	else error("streamin()" strcat(gds_fname " does not exists." )))
	xstInSetField("strmFile"  gds_fname)
	if(DEBUG then println(gds_suffix))
	xstInSetField("library"   FILL_LIB_NAME)
	xstInSetField("objectMap" OBJECTMAP )
	xstInSetField("layerMap"  LAYERMAP  )
	xstInSetField("logFile"   strcat(LIB_NAME "_" CELL_NAME "_" VIEW_NAME "_in.log")  )
	xstInSetField("enableColoring"  "true"  )
	;xstInSetField("attachTechFileOfLib"  "cmos22fdsoi"  )
	if( is_completion_box then 
		xstInSetField("showCompletionMsgBox" "true"  )
	else
		xstInSetField("showCompletionMsgBox" "false"  )
	)
	printf("Streamin in the file %s into library %s\n" gds_fname FILL_LIB_NAME)
	xstInDoTranslate()	
)) ; streamin()

if(IS_STRM_CALLBACK then
	procedure( xstInOnCompletion( status )
	prog( ( )
		printf("In xstInOnCompletion of XStream In GUI: %d\n" status)
		if( status == 0 then
			printf("Successfully completed\n" status)
			if( DO_TOP then
				create_top_layout( ?add_fill DO_FILL ?add_color DO_COLOR )
			)
		else
			printf("Error occured during translation\n" status)
		);if
		;reset - this is the last point in the code
		DO_FILL  = nil
		DO_TOP   = nil
		DO_COLOR = nil
		);prog
	) ; xstInOnCompletion
) ; if

; Need to debug why can't I use both key and rest together...
; procedure( zti_run_fill_script( @key (do_fill t) (do_color nil) @rest arg)
procedure( zti_run_fill_script( @key (do_fill t) (do_color nil) )
;printf("Function zti_run_fill_script is started")
let( (cmd_fill cmd_color zti_fname cwd)
	printf("Preparing for the fill script launch...\n")
	;checking if important files are present
	; GF's fill script needs to have all the technology files in a directory where the main script is located.
	; They can not handle absolute paths...
	files_needed=list("run_calibre" "fill_fdsoi22.enc.svrf" "TGP.gds" "EQ_CFILL.gds")
	foreach( f files_needed   check_fill_file(f)   )

	cwd=getWorkingDir()
	changeWorkingDir(WORK_DIR)
	zti_fname=strcat(WORK_DIR "/" CELL_NAME "_" VIEW_NAME)
	if(DEBUG then println(zti_fname))
	; xterm -e is needed otherwise Cadence freeze... Regardliess of the interface function sh, csh, system.
	; use -hold for debug, i.e. to see the terminal outputs, but use it only for debug. Cadence will not be responsive until this task is not finished.
	; I do not remember why do I need " \ " " at the end, and at this point I am too afraid to change.
	; cmd=strcat( "xterm -e \" ./run_calibre -l " GDS_OUT " -ln " CELL_NAME " -setup " check_fill_path(FILL_SETUP) " -swap_output_file " strcat(zti_fname ".swap.gds") " -merged_output_file " strcat(zti_fname ".merged.gds") " -output_filename " strcat(zti_fname ".filled.gds") arg " \" ") 
	cmd_fill  = strcat( "xterm -e \" ./run_calibre -l " GDS_OUT 
												 " -ln " CELL_NAME 
												 " -setup " check_fill_path(FILL_SETUP) 
												 " -swap_output_file " strcat(zti_fname ".swap.gds") 
												 " -merged_output_file " strcat(zti_fname ".merged.gds") 
												 " -output_filename " strcat(zti_fname ".filled.gds") 
												 " \" ") 
	cmd_color = strcat( "xterm -hold -e \" ./run_calibre -l " GDS_OUT 
												" -ln " CELL_NAME 
												" -setup " check_fill_path(COLOR_SETUP) 
												" -output_filename " strcat(zti_fname ".rebal.gds") 
												" \" ") 
	if( do_fill then
		printf("Command to run the fill script:\n%s\n" cmd_fill)
		system(cmd_fill)
		changeWorkingDir(MY_DF2_DIR)
		streamin( ?gds_suffix ".swap.gds" )
	)
	if( do_color then
		printf("Command to run the fill script:\n%s\n" cmd_color)
		system(cmd_color)
		changeWorkingDir(MY_DF2_DIR)
		streamin( ?gds_suffix ".rebal.gds" )
	)
	changeWorkingDir(cwd)

	;; reset
	;DO_FILL  = nil
	;DO_TOP   = nil
	;DO_COLOR = nil
)) ;zti_run_fill_script


procedure( create_top_layout( @key (add_fill t) (add_color nil))
let( (lay_view cv master_cv)
	if( VIEW_NAME=="layout" then
		error("The initial viewname was already layout. No \"layout\" view will be created, because otherwise the initial layout would be overwritten.")
	else 
		println("Top layout is being created...")
		println("Create a backup from the existing layout top cell view.")
		when(lay_view=dbOpenCellViewByType(LIB_NAME CELL_NAME "layout")
			cv_copy=dbCopyCellView(lay_view LIB_NAME CELL_NAME "layout_bck_fillerscript" nil nil t)	
			unless(cv_copy
				error("Copy of layout view was not successful\n")  )
			dbSave(cv_copy)
			dbClose(cv_copy)
		)

		cv=dbOpenCellViewByType(LIB_NAME CELL_NAME "layout" "maskLayout" "w")
		;Add the pre-fill layout and the filled layout
		if( cv then
			master_cv=dbOpenCellViewByType(LIB_NAME CELL_NAME VIEW_NAME)
			dbCreateInst(cv master_cv nil list(0 0) "R0")
			if(	add_fill then
				master_cv=dbOpenCellViewByType(strcat(LIB_NAME FILL_LIB_SUFFIX) strcat(CELL_NAME "_gf") "layout")
				dbCreateInst(cv master_cv nil list(0 0) "R0")
				println("Fill cellview has been added to top layout")
			)
			if(	add_color then
				master_cv=dbOpenCellViewByType(strcat(LIB_NAME FILL_LIB_SUFFIX) strcat(CELL_NAME "_gt") "layout")
				dbCreateInst(cv master_cv nil list(0 0) "R0")
				println("Coloring rebalance cellview has been added to top layout")
			)
			dbSave(cv)
			dbClose(cv)
			println("New top layout with fill has just been created.")
		else
			error("Top layout cellview could not be created. Check whether you have write permissions for it.")
			printf("Top cellview: %s/%s/%s." LIB_NAME CELL_NAME "layout")
		)
	);if
	println("The fill script has been finished.")
)) ; create_top_layout

;----------------------------------------------------------------------
; creating OUTLINE drw around the design automatically
procedure( zti_draw_bBoxRect(@optional (layer "OUTLINE") (purpose "drawing"))
	cv=geGetWindowCellView()
	dbReopen(cv "a")  
	dbCreateRect(cv list(layer purpose) cv~>bBox)
)
;----------------------------------------------------------------------
; Creating form
; Big problem: forms are defined before they are invoked. And it looks like that the field values does not change if the form is called again from a different cellview. Not clear how to solve it and it does not worth the time right now.
procedure(form()
let( (s_fillfile s_libout s_cellout s_viewout s_libin s_fillarg)
	s_fillfile = hiCreateStringField(
		?name 'fill_setup_file
		?prompt "Fill setup file"
		?value "cfill.setup"
		?defValue "cfill.setup"
		)
	browseBtn = hiCreateFormButton(
		?name `browseBtn
		?buttonText "Browse setup file..."
		?callback "ddsFileBrowseCB( hiGetCurrentForm() 'fill_setup_file)"
	)
	s_libout = hiCreateStringField(
		?name 'libout
		?prompt "Library of the design to be filled"
		?value hiGetCurrentWindow()~>topCellView~>libName
		;?value LIB_NAME
		;?defValue LIB_NAME
	)
	s_cellout = hiCreateStringField(
		?name 'cellout
		?prompt "Cell of the design to be filled"
		?value hiGetCurrentWindow()~>topCellView~>cellName
		;?value CELL_NAME
		;?defValue CELL_NAME
	)
	s_viewout = hiCreateStringField(
		?name 'viewout
		?prompt "Cellview of the design to be filled"
		?value hiGetCurrentWindow()~>topCellView~>viewName
		;?value VIEW_NAME
		;?defValue VIEW_NAME
	)
	s_libin = hiCreateStringField(
		?name 'libin
		?prompt "Stream-in library"
		?value strcat(LIB_NAME FILL_LIB_SUFFIX)
		;?defValue strcat(LIB_NAME FILL_LIB_SUFFIX)
	)
	s_fillarg = hiCreateStringField(
		?name 'fillarg
		?prompt "Additional command line arguments for the fill script"
	)
	r_create=hiCreateToggleField(
		?name 'is_create
		?choices list( list('create "Top \"layout\" creation") )
		?numSelect 1
		?itemsPerRow 1
		?value list(nil)
		?enabled t
	)

	if(boundp('TestForm) && hiIsForm(TestForm) then TestForm ;; return the form structure
		else hiCreateAppForm( ?name 'TestForm
			    ?formTitle "Filler setup file form"
			    ?callback 'getValue
			    ;?fields list( s_fillfile browseBtn s_libout s_cellout s_viewout s_libin s_fillarg )
; No need for the radio button at the moment
;			    ?fields list( s_fillfile browseBtn s_fillarg r_create )
			    ?fields list( s_fillfile browseBtn s_fillarg )
				?buttonLayout 'OKCancel
;				?buttonLayout list( 
;					list( 'Run_fill Run_fill_callback())
;					list('OKCancel "")
;				)
			)
	  ) ;if
))

procedure( check_fill_path(path)
let( (tmp)
	if(rexMatchp("/" path) ; if a path is given
		then tmp = path
		else tmp = strcat("/home/tibenszky/share/FILL/" path)   
	)
	tmp  ; maybe it is not needed
))

; get the value in a callback and set it as the fill file
procedure( getValue(form)
let( (f_in tmp lib cell view libin)
	f_in = form->fill_setup_file->value 
	tmp=check_fill_path(f_in)
	when(isFile(tmp)
		FILL_SETUP=tmp	
	)
;	LIB_NAME=form->libout->value
;	CELL_NAME=form->cellout->value
;	VIEW_NAME=form->viewout->value
;	FILL_LIB_NAME=form->libin->value
	FILL_ARG = form->fillarg->value
	DO_TOP = car(form->is_create->value)
))

procedure(Run_fill_callback()
	DO_FILL = t
	streamout()
)

procedure(create_form()
let( (myform)
	myform = form() ;; Create / update the form
	;; and display the form if it is not displayed
	unless(boundp('TestForm) && hiIsFormDisplayed(myform)
		hiDisplayForm(myform)
	)
))

;----------------------------------------------------------------------
; Adding Layout Menu
procedure( CCSCreateLayoutPulldownMenu()
if( boundp( 'CCSLayoutPulldownMenu )
	then CCSLayoutPulldownMenu
	else
	hiCreatePulldownMenu(
		'CCSLayoutPulldownMenu
		"22FDX_zti"
		list(
			hiCreateMenuItem( 
				?name 'Item1
				?itemText "Stream-out"
				?callback "CB_streamout_only()"
				)
			hiCreateMenuItem( 
				?name 'Item2
				?itemText "Fill setup"
				?callback "create_form()"
				)
			hiCreateMenuItem( 
				?name 'Item3
				?itemText "Fill without top layout creation"
				?callback "CB_fill_wo_top()"
				)
;			hiCreateMenuItem( 
;				?name 'Item4
;				?itemText "Fill and coloring without top layout creation"
;				?callback "CB_fill_color_wo_top()"
;				)
			hiCreateMenuItem( 
				?name 'Item5
				?itemText "Fill with top layout creation"
				?callback "CB_fill_top()"
				)
;			hiCreateMenuItem( 
;				?name 'Item6
;				?itemText "Fill and coloring  with top layout creation"
;				?callback "CB_fill_color_top()"
;				)
			hiCreateMenuItem( 
				?name 'Item7
				?itemText "Libraries used"
				?callback "print(find_Libs_Used())" ; another script needs to be loaded
				)
			hiCreateMenuItem( 
				?name 'Item8
				?itemText "Cells used"
				?callback "print(find_Cells_Used())" ; another script needs to be loaded

				)
			hiCreateMenuItem( 
				?name 'Item9
				?itemText "Draw OUTLINE"
				?callback "zti_draw_bBoxRect()"
				)
;			hiCreateMenuItem( 
;				?name 'Item10
;				?itemText "Coloring"
;				?callback "zti_coloring()"
;				)

		) ; list
	) ; hiCreatePulldownMenu
) ; if
) ; procedure

procedure(CB_streamout_only()
	DO_FILL  = nil
	DO_COLOR = nil
	DO_TOP 	 = nil
	get_cell_data()
	printf("Stream-out) of cell: %s/%s/%s" LIB_NAME CELL_NAME VIEW_NAME)
	streamout()
)

procedure(CB_fill_top()
	DO_FILL  = t
	DO_TOP   = t	
	DO_COLOR = nil
	get_cell_data()
	printf("Stream-out, filling, stream-in and top layout creation) of cell: %s/%s/%s" LIB_NAME CELL_NAME VIEW_NAME)
	streamout()
)

procedure(CB_fill_color_top()
	DO_FILL  = t
	DO_TOP   = t	
	DO_COLOR = t
	get_cell_data()
	printf("Stream-out, filling, coloring, stream-in and top layout creation) of cell: %s/%s/%s" LIB_NAME CELL_NAME VIEW_NAME)
	streamout()
)

procedure(CB_fill_wo_top()
	DO_FILL  = t
	DO_TOP 	 = nil
	DO_COLOR = nil
	get_cell_data()
	printf("Stream-out, filling and stream-in (without top layout creation) of cell: %s/%s/%s" LIB_NAME CELL_NAME VIEW_NAME)
	streamout()
)

procedure(CB_fill_color_wo_top()
	DO_FILL  = t
	DO_TOP   = t
	DO_COLOR = t
	get_cell_data()
	printf("Stream-out, filling, coloring and stream-in (without top layout creation) of cell: %s/%s/%s" LIB_NAME CELL_NAME VIEW_NAME)
	streamout()
)

procedure(zti_coloring()
	DO_FILL  = nil
	DO_TOP   = nil
	DO_COLOR = t
	get_cell_data()
	printf("Stream-out, filling, coloring and stream-in (without top layout creation) of cell: %s/%s/%s" LIB_NAME CELL_NAME VIEW_NAME)
	streamout()
)

procedure( CCSUserPostInstallTrigger(args)
	hiInsertBannerMenu( args->window  CCSCreateLayoutPulldownMenu()  length( hiGetBannerMenus( args->window))  )
) 

;; Triggers for adding to Layout Suite L and XL window
if(IS_MENU then
	deRegUserTriggers("maskLayout" nil nil 'CCSUserPostInstallTrigger)
	deRegUserTriggers("maskLayoutXL" nil nil 'CCSUserPostInstallTrigger)
)
