;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   pc_get_parameter.pro     ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  $Id$
;
;  Description:
;   Returns parameters in Pencil-units, after checking for their existence.
;   Checks first in run.in and then in start.in parameter lists.
;
;  Parameters:
;   * param       Name of the parameter to be returned or "" for setting up.
;   * label       Optional error label to be printed, if parameter is unfound.
;   * missing     Optional label of missing parameter to be printed, if unfound.
;   * datadir     Given data directory for loading the parameter structures.
;   * run_param   'run_pars' will be cached, and loaded if necessary.
;   * start_param 'start_pars' will be cached, and loaded if necessary.
;
;  Examples: (in ascending order of efficiency)
;  ============================================
;
;   Use cached parameter structures that are initially loaded once:
;   IDL> print, pc_get_parameter ('nu'[, datadir=datadir])
;   IDL> print, pc_get_parameter ('eta')
;   IDL> print, pc_get_parameter ('mu0')
;
;   Use given parameter structures and cache them:
;   IDL> print, pc_get_parameter ('nu', start_param=start_param, run_param=run_param)
;   IDL> print, pc_get_parameter ('eta')
;   IDL> print, pc_get_parameter ('mu0')
;


; Cleanup parameter cache, if requested, and return selected parameter.
function pc_get_parameter_cleanup, param, cleanup=cleanup

	common pc_get_parameter_common, start_par, run_par

	if (keyword_set (cleanup)) then begin
		undefine, start_par
		undefine, run_par
	endif

	return, param
end


; Generate parameter abbreviations.
function pc_generate_parameter_abbreviation, param, label=label

	common cdat, x, y, z, mx, my, mz, nw, ntmax, date0, time0, nghostx, nghosty, nghostz
	common cdat_limits, l1, l2, m1, m2, n1, n2, nx, ny, nz
	common cdat_grid, dx_1, dy_1, dz_1, dx_tilde, dy_tilde, dz_tilde, lequidist, lperi, ldegenerated

	if (strcmp (param, 'mu0_4_pi', /fold_case)) then begin
		mu0 = pc_get_parameter ('mu0', label=label)
		return, 4.0 * !DPi * mu0 ; Magnetic vacuum permeability * 4 pi [SI: V*s/(A*m)]
	end
	if (strcmp (param, 'eta_total', /fold_case)) then begin
		resistivities = pc_get_parameter ('iresistivity', label=label)
		eta = pc_get_parameter ('eta', label=label)
		eta_total = 0.0
		eta_found = 0
		for pos = 0, n_elements (resistivities)-1 do begin
			resistivity = resistivities[pos]
			if (any (strcmp (resistivity, ['shock',''], /fold_case))) then continue
			eta_found++
			if (strcmp (resistivity, 'eta-const', /fold_case)) then begin
				eta_total += eta
			end else if (any (strcmp (resistivity, 'eta-zdep', /fold_case))) then begin
				zdep_profile = pc_get_parameter ('zdep_profile', label=label)
				eta_z0 = pc_get_parameter ('eta_z0', label=label)
				eta_jump = pc_get_parameter ('eta_jump', label=label)
				eta_width = pc_get_parameter ('eta_width', label=label)
				if (strcmp (zdep_profile, 'cubic_step', /fold_case)) then begin
					if (eta_width eq 0.0) then eta_width = 5 * mean (1.0 / dz_1)
					eta_total += spread (eta + eta * (eta_jump - 1.) * cubic_step (z[n1:n2], eta_z0, -eta_width), [0, 1], [nx, ny])
				end else begin
					print, "WARNING: The zdep_profile '"+zdep_profile+"' is not yet implemented."
					eta_found--
				end
			end else begin
				print, "WARNING: The resistivity '"+resistivity+"' is not yet implemented."
				eta_found--
			end
		end
		if (eta_found le 0) then eta_total = !Values.D_NaN
		return, eta_total
	end

	return, !Values.D_NaN
end


; Get a parameter and look for alternatives.
function pc_get_parameter, param, label=label, missing=missing, dim=dim, datadir=datadir, start_param=start_param, run_param=run_param, cleanup=cleanup

	common pc_get_parameter_common, start_par, run_par

	if (keyword_set (start_param)) then start_par = start_param
	if (keyword_set (run_param)) then run_par = run_param
	if (n_elements (start_par) eq 0) then pc_read_param, obj=start_par, dim=dim, datadir=datadir, /quiet
	if (n_elements (run_par) eq 0) then pc_read_param, obj=run_par, dim=dim, datadir=datadir, /param2, /quiet
	start_param = start_par
	run_param = run_par

	if (param eq '') then return, pc_get_parameter_cleanup (!Values.D_NaN, cleanup=cleanup)

	; run.in parameters
	run_names = tag_names (run_par)
	if (strcmp (param, 'K_Spitzer', /fold_case)) then begin
		if (any (run_names eq "K_SPITZER")) then return, run_par.K_spitzer
		if (any (run_names eq "KPARA")) then return, run_par.Kpara
		if (any (run_names eq "KGPARA")) then return, run_par.Kgpara ; only for backwards compatibility, should be removed some day, because this belongs to the entropy module.
		if (not keyword_set (missing)) then missing = "'K_Spitzer' or 'KPARA'"
	end
	if (strcmp (param, 'K_sat', /fold_case)) then begin
		if (any (run_names eq "KSAT")) then return, run_par.Ksat
		if (not keyword_set (missing)) then missing = "'Ksat'"
	end
	index = where (run_names eq strupcase (param))
	if (index[0] ge 0) then return, pc_get_parameter_cleanup (run_par.(index[0]), cleanup=cleanup)

	; start.in parameters
	start_names = tag_names (start_par)
	index = where (start_names eq strupcase (param))
	if (index[0] ge 0) then return, pc_get_parameter_cleanup (start_par.(index[0]), cleanup=cleanup)

	; Some additional useful parameter abbreviations
	abbreviation = pc_generate_parameter_abbreviation (param, label=label)

	; Cleanup parameter cache, if requested
	dummy = pc_get_parameter_cleanup ('', cleanup=cleanup)

	; Return parameter abbreviation, if existent
	if (not finite (abbreviation[0], /NaN)) then return, abbreviation

	; Some additional useful constants
	if (strcmp (param, 'q_electron', /fold_case)) then return, 1.6021766d-19 ; Electron charge [A*s]
	if (strcmp (param, 'm_electron', /fold_case)) then return, 9.109383d-31 ; Electron mass [kg]
	if (strcmp (param, 'm_proton', /fold_case)) then return, 1.6726218d-27 ; Proton mass [kg]
	if (strcmp (param, 'k_Boltzmann', /fold_case)) then return, 1.3806488d-23 ; Boltzmann constant [J/K]
	if (strcmp (param, 'c', /fold_case)) then return, 299792458.d0 ; Speed of light [m/s]
	if (strcmp (param, 'pi', /fold_case)) then return, !DPi ; Precise value of pi

	; Non-existent parameter
	message = "find"
	if (keyword_set (label)) then message = "compute '"+label+"' without"
	if (not keyword_set (missing)) then missing = param
	print, "ERROR: Can't "+message+" parameter "+missing

	return, !Values.D_NaN
end

