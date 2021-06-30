; technology constraints
; contraint for [__]  [__]  [__] like vias
l_constr_wide = list(
;				min_via(Y), min_via(X), Dend, Dvia
	list("V1" list(0.08 0.040 0.030 0.100))
	list("AY" list(0.08 0.040 0.030 0.100))
	list("AX" list(0.09 0.044 0.036 0.092))
)
; constraint for roatated - compared to above - vias: Y dimension hihger than X. Vias in X dimension.
l_constr_high = list(
;				min_via(Y), min_via(X), Dend, Dvia
	list("V1" list(0.08 0.040 0.020 0.080))  ; assuming M1 width is smaller than 200nm
	list("AY" list(0.08 0.040 0.020 0.080)) 
;	list("AX" list(0.09 0.044 0.023 0.092))
	list("AX" list(0.09 0.044 0.023 0.072))
)
l_via = list(
	list("V1" "V1")
	list("AY" "AY")
	list("A1" "AX")
	list("A2" "AX")
	list("A3" "AX")
	list("A4" "AX")
)

l_layers = list( "M1" "V1" "M2" "AY" "C1" "A1" "C2" "A2" "C3" "A3" "C4" )

procedure(coord_shift(l_xy l_shift)
	list(car(l_xy)+car(l_shift) cadr(l_xy)+cadr(l_shift))
)

procedure(My_via(cv w l_bottomleft l_constraint mbot height via2bottom @optional (precision 1e-3)) 
let( (l_c Xvia Yvia Dend Dvia_min Nvia Dvia x i)
	; search for via and top metal name based on bottom metal
	via=nil
	mtop=nil
	for( i 0 length(l_layers) 
		if( nth(i l_layers)==mbot then 
			via = nth(i+1 l_layers)
			mtop = nth(i+2 l_layers)
		)	
	) ;for
	viatype  = cadr(assoc(via l_via))
	l_c      = cadr(assoc(viatype l_constraint))
	Yvia     = nth(0 l_c) 
	Xvia     = nth(1 l_c) 
	Dend     = nth(2 l_c)
	Dvia_min = nth(3 l_c)
	Nvia     = floor((w-2*Dend-Xvia)/(Dvia_min+Xvia))+1
	Dvia     = floor((w-2*Dend-Nvia*Xvia)/(Nvia-1)/precision)*precision 
	Dend     = floor((w-Nvia*Xvia-(Nvia-1)*Dvia)/2/precision)*precision

	rectRodObj_Mb = rodCreateRect(
			?name     strcat("via_b" mbot mtop)
			?cvId     cv
			?layer    list(mbot "drawing")
			?width    w
			?length   height
			?origin   l_bottomleft
	  )
;	rectRodObj_Mt = rodCreateRect(
;			?name     strcat("via_t" mbot mtop)
;			?cvId     cv
;			?layer    list(mtop "drawing")
;			?width    w
;			?length   height
;			?origin   l_bottomleft
;	  )

	; Dend from the edge:
	x=Dend
	; iterator for naming
	i=0
	; If there is still place to add a via
	while( x+Xvia+Dend < w+1e-3
		Xcoord = car(l_bottomleft) + x
		Ycoord = cadr(l_bottomleft)
		rectRodObj_V = rodCreateRect(
				?name     strcat("via_v" mbot mtop sprintf(s "%d" i))
				?cvId     cv
				?layer    list(via "drawing")
				?width    Xvia
				?length   Yvia
				?origin   coord_shift(Xcoord:Ycoord 0:via2bottom)
		  )
		;printf("%f\t\t%f<=%f\n" x x+Dvia+Yvia+Dend w)	
		x = x + Xvia + Dvia
		i = i + 1
	)
	;printf("Last value - too close to edge - %f\n" x)
	;printf("metal_bottom: %s\tx:%f\tx+Xvia+Dend:%f\tw:%f\n" mbot x x+Xvia+Dend w)

	;; create a stretch handle for the width, in the X dimension, it
	  ;; will display as "width = <value>" and change by 0.1 increments
	  rodAssignHandleToParameter(
		 ?parameter          "w"
		 ?rodObj             rectRodObj_Mb
		 ?handleName         "centerRight"
		 ?stretchDir         "X"
		 ?displayName        "width"
		 ?displayExpression  "w"
	  ); rodAssignHandleToParameter
)) ; My_pcell


