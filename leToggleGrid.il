; zoltan.tibenszky@gmail.com
; v0: 2017-06-08
; v0.1.1: 2017-06-13; Bug fix; winId
; v0.2: 2018-02-06: added Banner Label to display the grid

zti_leGrids=list(0.005 0.01 0.1 1.0 5.0)

procedure(zti_leToggleGrid(@optional winID)
let( (currentGrid newGrid i winId)
	winId       = hiGetCurrentWindow()
	currentGrid = winId~>xSnapSpacing
	newGrid=0   ; variable denoting the grid to be set

	; determining the next biggest grid
	i=1			; iteration variable
	while( newGrid==0 && i<=length(zti_leGrids)
	let( (tmp)
		tmp=nthelem(i zti_leGrids)
		if( (tmp>currentGrid) newGrid=tmp)
		i+=1
	))

	; If current grid is greater or equal than the highest grid setting
	if( (newGrid==0) newGrid=car(zti_leGrids))

	if( (!winID) winID=hiGetCurrentWindow() )
	winID~>xSnapSpacing = newGrid
	winID~>ySnapSpacing = newGrid
	sprintf(str_newGrid "%.3f" newGrid)
	printf("Layout snap grid set to %L.\n" newGrid)
	hiChangeBannerLabel(winID str_newGrid 0)
))
