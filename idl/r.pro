;;;;;;;;;;;;;;;
;;;  r.pro  ;;;
;;;;;;;;;;;;;;;

;;; Read the data produced on one processor
;;; Assumes you have run `start.pro' once before.

;
;  read data
;
if ((n_elements(started) le 0) or (n_elements(read_all) gt 0)) then begin
  message, "You need to run start.pro first: use `.rnew start'"
endif
undefine, read_all
;
default, datadir, 'tmp'
default, file, 'var.dat'
;
uu    = fltarr(mx,my,mz,3)*one
lnrho = fltarr(mx,my,mz  )*one
if (lentropy)  then ss = fltarr(mx,my,mz  )*one
if (lmagnetic) then aa = fltarr(mx,my,mz,3)*one
;
;
;  Read startup parameters
;
pfile=datatopdir+'/'+'param2.dat'
dummy=findfile(pfile, COUNT=cpar)
if (cpar gt 0) then begin
  cs0=(nu=zero)
  hcond0=(hcond1=(hcond2=(whcond=zero)))
  cheat=(wheat=(cool=(whcond=zero)))
  Fheat=zero
  openr,1, pfile, /F77
  readu,1, cs0,nu
  readu,1, hcond0,hcond1,hcond2,whcond
  readu,1, cheat,wheat,cool,wcool
  readu,1, Fheat
  close,1
endif else begin
  print, 'Warning: cannot find file ', pfile
endelse

;
;  Read data
;
;AB: the following is not quite save, nvar=7 could mean other things...
;
close,1
openr,1, datadir+'/'+file, /F77
  if (lentropy and lmagnetic)           then readu,1, uu, lnrho, ss, aa
  if ((not lentropy) and lmagnetic)     then readu,1, uu, lnrho, aa
  if (lentropy and not lmagnetic)       then readu,1, uu, lnrho, ss
  if ((not lentropy) and not lmagnetic) then readu,1, uu, lnrho
readu,1, t, x, y, z
close,1
;
xx = spread(x, [1,2], [my,mz])
yy = spread(y, [0,2], [mx,mz])
zz = spread(z, [0,1], [mx,my])
rr = sqrt(xx^2+yy^2+zz^2)
;
;  Summarise data
;
xyz = ['x', 'y', 'z']
fmt = '(A,4G15.6)'
print, ' var        minval         maxval            mean           rms'
for j=0,2 do $
    print, FORMAT=fmt, 'uu_'+xyz[j]+' =', $
    minmax(uu(*,*,*,j)), mean(uu(*,*,*,j),/DOUBLE), rms(uu(*,*,*,j),/DOUBLE)
print, FORMAT=fmt, 'lnrho  =', $
    minmax(lnrho), mean(lnrho,/DOUBLE), rms(lnrho,/DOUBLE)
if (lentropy) then $
    print, FORMAT=fmt, 'ss  =', $
      minmax(ss), mean(ss,/DOUBLE), rms(ss,/DOUBLE)
if (lmagnetic) then $
    for j=0,2 do $
      print, FORMAT=fmt, 'aa_'+xyz[j]+' =', $
      minmax(aa(*,*,*,j)), mean(aa(*,*,*,j),/DOUBLE), rms(aa(*,*,*,j),/DOUBLE)
;
print,'t = ',t
;
END

; End of file
