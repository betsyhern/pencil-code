; +
; NAME:
;       PC_READ
;
; PURPOSE:
;       Pencil-Code unified reading routine.
;       Reads data from a snapshot file generated by a Pencil Code run.
;       This routine automatically detects HDF5 and old binary formats.
;
; CALLING:
;       pc_read, quantity, filename=filename, datadir=datadir, trimall=trim, processor=processor, dim=dim, start=start, count=count
;
; PARAMETERS:
;       quantity [string]: f-array component to read (mandatory).
;       filename [string]: name of the file to read. Default: last opened file
;       datadir [string]: path to the data directory. Default: 'data/'
;       trimall [boolean]: do not read ghost zones. Default: false
;       processor [integer]: number of processor subdomain to read. Default: all
;       dim [structure]: dimension structure. Default: load if needed
;       start [integer]: start reading at this grid position (includes ghost cells)
;       count [integer]: number of grid cells to read from starting position
;       close [boolean]: close file after reading
;
; EXAMPLES:
;       Ax = pc_read ('ax', file='var.h5') ;; open file 'var.h5' and read Ax
;       Ay = pc_read ('ay', /trim) ;; read Ay without ghost cells
;       Az = pc_read ('az', processor=2) ;; read data of processor 2
;       ux = pc_read ('ux', start=[47,11,13], count=[16,8,4]) ;; read subvolume
;       aa = pc_read ('aa') ;; read all three components of a vector-field
;
; MODIFICATION HISTORY:
;       $Id$
;       07-Apr-2019/PABourdin: coded
;
function pc_read, quantity, filename=filename, datadir=datadir, trimall=trim, processor=processor, dim=dim, start=start, count=count, close=close

	COMPILE_OPT IDL2,HIDDEN

	common pc_read_common, file

	vectors = [ 'aa', 'uu', 'bb', 'jj' ]
	vector = where (vectors eq strlowcase (quantity))
	if (vector[0] ge 0) then begin
		quantity = strmid (quantity, 0, strlen (quantity) - 1) + [ 'x', 'y', 'z' ]
	end

	num_quantities = n_elements (quantity)
	if (num_quantities gt 1) then begin
		; read multiple quantities in one large array
		data = pc_read (quantity[0], filename=filename, datadir=datadir, trimall=trim, processor=processor, dim=dim, start=start, count=count)
		sizes = size (data, /dimensions)
		dimensions = size (data, /n_dimensions)
		for pos = 1, num_quantities-1 do begin
			tmp = pc_read (quantity[pos], filename=filename, datadir=datadir, trimall=trim, processor=processor, dim=dim, start=start, count=count)
			if (dimensions eq 1) then begin
				data = [ data, tmp ]
			end else if (dimensions eq 2) then begin
				data = [ [data], [tmp] ]
			end else begin
				data = [ [[data]], [[tmp]] ]
			end
		end
		tmp = !Values.D_NaN
		if (keyword_set (close)) then h5_close_file
		data = reform (data, [ sizes, num_quantities ])
		return, data
	end

	particles = (strpos (strlowcase (quantity) ,'part/') ge 0)

	if (keyword_set (filename)) then begin
		if (not keyword_set (datadir)) then datadir = pc_get_datadir (datadir)
		file = datadir+'/allprocs/'+filename
	end else begin
		if (not keyword_set (file)) then begin
			; no file is open
			if (not keyword_set (datadir)) then datadir = pc_get_datadir (datadir)
			if (file_test (datadir+'/allprocs/var.h5')) then begin
				filename = 'var.h5'
				file = datadir+'/allprocs/'+filename
			end else begin
				; no HDF5 file found
				if (not file_test (datadir+'/proc0/var.dat') and not file_test (datadir+'/allprocs/var.dat')) then begin
					message, 'pc_read: ERROR: please either give a filename or open a HDF5 file!'
				end
				; read old file format
				return, pc_read_old (quantity, filename=filename, datadir=datadir, trimall=trim, processor=processor, dim=dim, start=start, count=count)
			end
		end
	end

	if (size (processor, /type) ne 0) then begin
		if (keyword_set (particles)) then begin
			distribution = h5_read ('proc/distribution', filename=file)
			start = 0
			if (processor ge 1) then start = total (distribution[0:processor-1])
			count = distribution[processor]
			return, h5_read (quantity, start=start, count=count, close=close)
		end else begin
			if (size (dim, /type) eq 0) then pc_read_dim, obj=dim, datadir=datadir, proc=proc
			ipx = processor mod dim.nprocx
			ipy = (processor / dim.nprocx) mod dim.nprocy
			ipz = processor / (dim.nprocx * dim.nprocy)
                        nx = dim.nxgrid / dim.nprocx
                        ny = dim.nygrid / dim.nprocy
                        nz = dim.nzgrid / dim.nprocz
                        ghost = [ dim.nghostx, dim.nghosty, dim.nghostz ]
			start = [ ipx*nx, ipy*ny, ipz*nz ]
			count = [ nx, ny, nz ] + ghost * 2
		end
	end

	if (not keyword_set (particles)) then begin
		if (strpos (strlowcase (quantity), '/') lt 0) then quantity = 'data/'+quantity
		if (strpos (quantity, 'data/time') ge 0) then quantity = 'time'
		if (keyword_set (trim)) then begin
			default, start, [ 0, 0, 0 ]
			default, count, [ dim.mxgrid, dim.mygrid, dim.mzgrid ]
			if (size (dim, /type) eq 0) then pc_read_dim, obj=dim, datadir=datadir
                        ghost = [ dim.nghostx, dim.nghosty, dim.nghostz ]
			degenerated = where (count eq 1, num_degenerated)
			if (num_degenerated gt 0) then ghost[degenerated] = 0
			return, h5_read (quantity, filename=file, start=start+ghost, count=count-ghost*2, close=close)
		end
	end

	return, h5_read (quantity, filename=file, start=start, count=count, close=close)
end

