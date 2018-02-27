;TOGGLE_VISIBILITY_BINDKEY = "Ctrl Shift<Key>V"
;TOGGLE_SELECTABILITY_BINDKEY = "Ctrl Shift<Key>S"

procedure(zti_leNothingVisible()
	leSetAllLayerVisible(nil)
	hiRedraw()
	hiSetBindKey("Layout" TOGGLE_VISIBILITY_BINDKEY "zti_leAllVisible()")
)

procedure(zti_leAllVisible()
	leSetAllLayerVisible(t)
	hiRedraw()
	hiSetBindKey("Layout" TOGGLE_VISIBILITY_BINDKEY "zti_leNothingVisible()")
)

procedure(zti_leNothingSelectable()
	leSetAllLayerSelectable(nil)
	hiRedraw()
	hiSetBindKey("Layout" TOGGLE_SELECTABILITY_BINDKEY "zti_leAllSelectable()")
)

procedure(zti_leAllSelectable()
	leSetAllLayerSelectable(t)
	hiRedraw()
	hiSetBindKey("Layout" TOGGLE_SELECTABILITY_BINDKEY "zti_leNothingSelectable()")
)

;hiSetBindKey("Layout" TOGGLE_SELECTABILITY_BINDKEY "zti_leAllSelectable()")
;hiSetBindKey("Layout" TOGGLE_VISIBILITY_BINDKEY "zti_leAllVisible()")
