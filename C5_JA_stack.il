; replaces all C6YXIA via with C5YSJA and deletes all C5A5C6 via
; If C6 is used anything other than in viastacks, it would cause opens/shorts. Take care!
procedure( port_C5_IA_stack(lib cell) 
let( (my_cell tf viaDef)
	my_cell=dbOpenCellViewByType(lib cell "layout" "" "a")	
	tf=techGetTechFile(ddGetObj(lib))
	viaDef=techFindViaDefByName(tf "C5YSJA")
	foreach( via setof( x my_cell~>vias x~>viaHeader~>viaDef~>name=="C6YXIA")
		if(dbCreateVia(my_cell viaDef via~>origin via~>orient ~>viaHeader~>overrideParams) then 
			dbDeleteObject(via)
		)
	)
	foreach( via setof( x my_cell~>vias x~>viaHeader~>viaDef~>name=="C5A5C6")
		dbDeleteObject(via)
	)
)) ; port_C5_IA_stack()
