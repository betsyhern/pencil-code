;;;;;;;;;;;;;;;;;;;;;
;;;   pvert.pro   ;;;
;;;;;;;;;;;;;;;;;;;;;

;;;
;;;  Author: wd (Wolfgang.Dobler@ncl.ac.uk)
;;;  Date:   11-Nov-2001
;;;
;;;  Description:
;;;   Plot vertical profiles of uz, lnrho and entropy.

default, pvert_layout, [0,2,2]
default, nprofs, 10              ; set to N for only N profiles, 0 for all

s = texsyms()

nign = 3                        ; Number of close-to-bdry points to ignore

;
; construct vector of vertical pencils to plot
;
Nxmax = mx-2*nign
Nymax = my-2*nign
Nmax = Nxmax*Nymax
if ((nprofs le 0) or (nprofs gt Nmax)) then nprofs = Nmax
ixp=[[mx/2]] & iyp=[[my/2]]     ; case nprofs=1
if (nprofs gt 1) then begin
  Nxp = sqrt(nprofs+1e-5)*Nxmax/Nymax
  Nyp = sqrt(nprofs+1e-5)*Nymax/Nxmax
  Nxyp = Nxp*Nyp
  ixp = nign + spread( indgen(Nxp)*Nxmax/Nxp, 1, Nyp )
  iyp = nign + spread( indgen(Nyp)*Nymax/Nyp, 0, Nxp )
  ixp = floor(ixp)
  iyp = floor(iyp)
endif

save_state

!p.multi = pvert_layout

if (!d.name eq 'X') then begin
  !p.charsize = 1. + (max(!p.multi)-1)*0.3
endif

!y.title = '!8z!X'

for ivar = 0,3 do begin

  case ivar of
    0: begin
      var = lnrho
      title = '!6ln '+s.varrho
      xr = minmax(var)
      if (n_elements(lnrhoinit) gt 0) then xr = minmax([xr,lnrhoinit])
    end
    1: begin
      var = uu[*,*,*,2]
      title = '!8u!Dz!N!X'
      xr = minmax(var)
    end
    2: begin
      var = ss
      title = '!6Entropy !8s!X'
      xr = minmax(var)
      if (n_elements(ssinit) gt 0) then xr = minmax([xr,ssinit])
    end
    3: begin
      var = gamma/gamma1*exp(gamma*ss+gamma1*lnrho)
      title = '!6Temperature !8T!X'
      xr = minmax(var)
      if (n_elements(Tinit) gt 0) then xr = minmax([xr,Tinit])
    end
  endcase

  plot, z, z, /NODATA, $
      XRANGE=xr, XSTYLE=3, $
      YRANGE=minmax(z), YSTYLE=3,  $
      TITLE=title
  for ix=0,(size(ixp))[1]-1 do begin
    for iy=0,(size(ixp))[2]-1 do begin
      oplot, var[ixp[ix,iy],iyp[ix,iy],*], z
    endfor
  endfor
  ophline, [z0,z1,z2,ztop]
  if (ivar eq 1) then opvline

;; overplot initial profiles
  if (n_elements(Tinit) le 0) then begin
    if (ivar eq 0) then $
        message, 'No Tinit -- you should run thermo.pro', /INFO
  endif else begin
    case ivar of
      0: oplot, lnrhoinit, z, LINE=2, COLOR=130, THICK=2
      1: ;nothing to overplot
      2: oplot, ssinit, z, LINE=2, COLOR=130, THICK=2
      3: oplot, Tinit, z, LINE=2, COLOR=130, THICK=2
    endcase
  endelse

endfor

restore_state

end
; End of file pvert.pro


