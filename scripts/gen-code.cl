;;; Qcint is a general GTO integral library for computational chemistry
;;; Copyright (C) 2014 Qiming Sun <osirpt.sun@gmail.com>
;;;
;;; This file is part of Qcint.
;;;
;;; Qcint is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

(load "utility.cl")
(load "parser.cl")
(load "derivator.cl")

; TODO
;
;(defun gen-raw-output (foutput vs1 &optional vs2)
;  (format foutput "~%e1:")
;  (format foutput "~a" vs1)
;  (format foutput "~%e2:")
;  (format foutput "~a" vs2))
;
;(defun gen-tex-subscript (foutput vs1 &optional vs2)
;  (defun tex-subscript-filter (cell)
;    (format foutput "~a,~{~a~},~{~a~} "
;            (phase-of cell)
;            (scripts-of (consts-of cell))
;            (scripts-of (ops-of cell))))
;  (gen-subscript (set-cells-streamer #'tex-subscript-filter foutput)
;                 (tensor-of-cellss vs1 vs2)))
;
;(defun gen-ternary-subscript (foutput vs1 &optional vs2)
;  (defun ternary-filter (cell)
;    (format foutput "~a,~a,~a "
;            (phase-of cell)
;            (ternary-subscript (consts-of cell))
;            (ternary-subscript (ops-of cell))))
;  (gen-subscript (set-cells-streamer #'ternary-filter foutput)
;                 (tensor-of-cellss vs1 vs2)))

(defun gen-subscript (cells-streamer raw-script)
  (labels ((gen-tex-iter (raw-script)
             (cond ((null raw-script) raw-script)
                   ((vector? raw-script)
                    (gen-tex-iter (comp-x raw-script))
                    (gen-tex-iter (comp-y raw-script))
                    (gen-tex-iter (comp-z raw-script)))
                   ((cells? raw-script)
                    (funcall cells-streamer raw-script))
                   (t (mapcar cells-streamer raw-script)))))
    (gen-tex-iter raw-script)))

(defun convert-from-n-sys (ls n)
  (reduce (lambda (x y) (+ (* x n) y)) ls
          :initial-value 0))

(defun xyz-to-ternary (xyzs)
  (cond ((eql xyzs 'x) 0)
        ((eql xyzs 'y) 1)
        ((eql xyzs 'z) 2)
        (t (error " unknown subscript ~a" xyzs))))

(defun ternary-subscript (ops)
  "convert the polynomial xyz to the ternary"
  (cond ((null ops) ops)
        (t (convert-from-n-sys (mapcar #'xyz-to-ternary 
                                       (remove-if (lambda (x) (eql x 's))
                                                  (scripts-of ops)))
                               3))))
(defun gen-c-block (fout fmt-gout raw-script)
  (let ((ginc -1))
    (labels ((c-filter (cell)
               (let ((fac (realpart (phase-of cell)))
                     (const@3 (ternary-subscript (consts-of cell)))
                     (op@3    (ternary-subscript (ops-of cell))))
                 (cond ((null const@3)
                        (if (null op@3)
                          (format fout " + (~a*s\[0\])" fac)
                          (format fout " + (~a*s\[~a\])"
                                  fac op@3)))
                       ((null op@3)
                        (format fout " + (~a*c\[~a\]*s\[0\])"
                                fac const@3))
                       (t (format fout " + (~a*c\[~a\]*s\[~a\])"
                                  fac const@3 op@3)))))
             (c-streamer (cs)
               (format fout fmt-gout (incf ginc))
               (cond ((null cs) (format fout " 0"))
                     ((cell? cs) (c-filter cs))
                     (t (mapcar #'c-filter cs)))
               (format fout ";~%")))
      (gen-subscript #'c-streamer raw-script)
      (1+ ginc))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; effective keys are p,r,ri,...
(defun effect-keys (ops)
  (remove-if-not (lambda (x)
                   (member x (append '(nabla-rinv nabla-r12)
                                     *intvar-keywords*)))
                 ops))
(defun g?e-of (key)
  (case key
    ((p ip nabla px py pz p* ip* nabla* px* py* pz*) "D_")
    ((r x y z) "R_") ; the vector origin is on the center of the basis it acts on
    ((ri rj rk rl) "RC") ; the vector origin is R[ijkl]
    ((r0 g) "R0") ; R0 ~ the vector origin is (0,0,0)
    ((rc) "RC") ; the vector origin is set in env[PTR_COMMON_ORIG]
    ((nabla-rinv nabla-r12) "D_")
    (otherwise (error "unknown key ~a" key))))

(defun dump-header (fout)
  (format fout "/*
 * Qcint is a general GTO integral library for computational chemistry
 * Copyright (C) 2014 Qiming Sun <osirpt.sun@gmail.com>
 *
 * This file is part of Qcint.
 *
 * Qcint is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/*
 * Description: code generated by  gen-code.cl
 */
#include <pmmintrin.h>
#include \"cint_bas.h\"
#include \"cart2sph.h\"
#include \"g2e.h\"
#include \"optimizer.h\"
#include \"cint1e.h\"
#include \"cint2e.h\"
#include \"misc.h\"
#include \"fblas.h\"
#include \"c2f.h\"
"))

(defun dump-declare-dri-for-rc (fout i-ops symb)
  (when (member 'rc i-ops)
    (format fout "double dr~a[3];~%" symb)
    (format fout "dr~a[0] = r~a[0] - env[PTR_COMMON_ORIG+0];~%" symb symb)
    (format fout "dr~a[1] = r~a[1] - env[PTR_COMMON_ORIG+1];~%" symb symb)
    (format fout "dr~a[2] = r~a[2] - env[PTR_COMMON_ORIG+2];~%" symb symb))
  (when (member 'ri i-ops)
    (format fout "double dr~a[3];~%" symb)
    (format fout "dr~a[0] = r~a[0] - ri[0];~%" symb symb)
    (format fout "dr~a[1] = r~a[1] - ri[1];~%" symb symb)
    (format fout "dr~a[2] = r~a[2] - ri[2];~%" symb symb))
  (when (member 'rj i-ops)
    (format fout "double dr~a[3];~%" symb)
    (format fout "dr~a[0] = r~a[0] - rj[0];~%" symb symb)
    (format fout "dr~a[1] = r~a[1] - rj[1];~%" symb symb)
    (format fout "dr~a[2] = r~a[2] - rj[2];~%" symb symb))
  (when (member 'rk i-ops)
    (format fout "double dr~a[3];~%" symb)
    (format fout "dr~a[0] = r~a[0] - rk[0];~%" symb symb)
    (format fout "dr~a[1] = r~a[1] - rk[1];~%" symb symb)
    (format fout "dr~a[2] = r~a[2] - rk[2];~%" symb symb))
  (when (member 'rl i-ops)
    (format fout "double dr~a[3];~%" symb)
    (format fout "dr~a[0] = r~a[0] - rl[0];~%" symb symb)
    (format fout "dr~a[1] = r~a[1] - rl[1];~%" symb symb)
    (format fout "dr~a[2] = r~a[2] - rl[2];~%" symb symb)))

(defun dump-declare-giao-ij (fout bra ket)
  (let ((n-giao (count 'g (append bra ket))))
    (when (> n-giao 0)
      (format fout "double rirj[3], c[~a];~%" (expt 3 n-giao))
      (format fout "rirj[0] = ri[0] - rj[0];~%" )
      (format fout "rirj[1] = ri[1] - rj[1];~%" )
      (format fout "rirj[2] = ri[2] - rj[2];~%" )
      (loop
        for i upto (1- (expt 3 n-giao)) do
        (format fout "c[~a] = 1" i)
        (loop
          for j from (1- n-giao) downto 0
          and res = i then (multiple-value-bind (int res) (floor res (expt 3 j))
                             (format fout " * rirj[~a]" int)
                             res))
        (format fout ";~%")))))

; l-combo searches op_bit from left to right
;  o100 o010 o001|g...>  =>  |g...> = o100 |g0..>
;  |g100,l> = o100 |g000,l+1>
;  |g101,l> = o100 |g001,l+1>
;  |g110,l> = o100 |g010,l+1>
;  |g111,l> = o100 |g011,l+1>
; r-combo searches op_bit from right to left
;  o100 o010 o001|g...>  =>  |g...> = o001 |g..0>
;  |g100,l+2> = o100 |g000,l+3>
;  |g101,l  > = o001 |g100,l+1>
;  |g110,l+1> = o010 |g100,l+2>
;  |g111,l  > = o001 |g110,l+1>
; [lr]-combo have no connection with <bra| or |ket>
;    def l_combinator(self, ops, ig, mask, template):
(defun first-bit1 (n)
  (loop
    for i upto 31
    thereis (if (zerop (ash n (- i))) (1- i))))
(defun last-bit1 (n)
  (loop
    for i upto 31
    thereis (if (oddp (ash n (- i))) i)))
(defun combo-bra (fout fmt ops-rev n-ops ig mask)
  (let* ((right (first-bit1 (ash ig (- mask))))
         (left (- n-ops right 1))
         (ig0 (- ig (ash 1 (+ mask right))))
         (op (nth right ops-rev)))
    (format fout fmt (g?e-of op) ig ig0 left)))
(defun combo-opj (fout fmt-op fmt-j opj-rev j-len ig mask)
  (let ((right (last-bit1 (ash ig (- mask)))))
    (if (< right j-len) ; does not reach op yet
      (combo-ket fout fmt-j opj-rev ig mask)
      (let ((ig0 (- ig (ash 1 (+ mask right))))
            (op (nth right opj-rev)))
        (if (member op '(nabla-rinv nabla-r12))
          (format fout fmt-op
                  (g?e-of op) ig ig0 right
                  (g?e-of op) (1+ ig) ig0 right
                  ig (1+ ig))
          (format fout fmt-j (g?e-of op) ig ig0 right))))))
(defun combo-ket (fout fmt ops-rev ig mask)
  (let* ((right (last-bit1 (ash ig (- mask))))
         (ig0 (- ig (ash 1 (+ mask right))))
         (op (nth right ops-rev)))
    (format fout fmt (g?e-of op) ig ig0 right)))

(defun power2-range (n &optional (shift 0))
  (range (+ shift (ash 1 n)) (+ shift (ash 1 (1+ n)))))
(defun dump-combo-braket (fout fmt-i fmt-op fmt-j i-rev op-rev j-rev mask)
  (let* ((i-len (length i-rev))
         (j-len (length j-rev))
         (op-len (length op-rev))
         (opj-rev (append j-rev op-rev)))
    (loop
      for right from mask to (+ mask j-len op-len -1) do
      (loop
        for ig in (power2-range right) do
        (combo-opj fout fmt-op fmt-j opj-rev j-len ig mask)))
    (let ((shft (+ op-len j-len mask)))
      (loop
        for right from shft to (+ shft i-len -1) do
        (loop
          for ig in (power2-range right) do
          (combo-bra fout fmt-i i-rev i-len ig shft))))))

(defun dec-to-ybin (n)
  (parse-integer (substitute #\0 #\2 (write-to-string n :base 3))
                 :radix 2))
(defun dec-to-zbin (n)
  (parse-integer (substitute #\1 #\2
                             (substitute #\0 #\1
                                         (write-to-string n :base 3)))
                 :radix 2))
(defun dump-s-1e (fout n)
  (format fout "for (n = 0; n < nf; n++, idx+=3) {
ix = idx[0];
iy = idx[1];
iz = idx[2];~%")
  (loop
    for i upto (1- (expt 3 n)) do
    (let* ((ybin (dec-to-ybin i))
           (zbin (dec-to-zbin i))
           (xbin (- (ash 1 n) 1 ybin zbin)))
      (format fout "s[~a] = g~a[ix] * g~a[iy] * g~a[iz];~%"
              i xbin ybin zbin))))

(defun name-c2sor (sfx sp sf ts)
  (cond ((eql sp 'spinor)
         (if (eql sf 'sf)
           (if (eql ts 'ts)
             (format nil "&c2s_sf_~a" sfx)
             (format nil "&c2s_sf_~ai" sfx))
           (if (eql ts 'ts)
             (format nil "&c2s_si_~a" sfx)
             (format nil "&c2s_si_~ai" sfx))))
         ((eql sp 'spheric)
          (format nil "&c2s_sph_~a" sfx))
         (t (format nil "&c2s_cart_~a" sfx))))

(defun gen-code-int1e (fout intname raw-infix &optional (sp 'spinor))
  (destructuring-bind (op bra-i ket-j bra-k ket-l)
    (split-int-expression raw-infix)
    (let* ((i-rev (effect-keys bra-i)) ;<i| already in reverse order
           (j-rev (reverse (effect-keys ket-j)))
           (op-rev (reverse (effect-keys op)))
           (i-len (length i-rev))
           (j-len (length j-rev))
           (op-len (length op-rev))
           (tot-bits (+ i-len j-len op-len))
           (raw-script (eval-int raw-infix))
           (ts (car raw-script))
           (sf (cadr raw-script))
           (goutinc))
      (format fout "/* <~{~a ~}i|~{~a ~}|~{~a ~}j> */~%" bra-i op ket-j)
      (format fout "static void CINTgout1e_~a(double *g,
double *gout, const int *idx, const CINTEnvVars *envs) {~%" intname)
      (format fout "const double *env = envs->env;
const int nf = envs->nf;
const int i_l = envs->i_l;
const int j_l = envs->j_l;
const double *ri = envs->ri;
const double *rj = envs->rj;
int ix, iy, iz, n;
double *g0 = g;~%")
      (loop
        for i in (range (ash 1 tot-bits)) do
        (format fout "double *g~a = g~a  + envs->g_size * 3;~%" (1+ i) i))
      (format fout "double s[~a];~%" (expt 3 tot-bits))
      (dump-declare-dri-for-rc fout bra-i "i")
      (dump-declare-dri-for-rc fout (append op ket-j) "j")
      (dump-declare-giao-ij fout bra-i (append op ket-j))
;;; generate g_(bin)
;;; for the operators act on the |ket>, the reversed scan order and r_combinator
;;; is required; for the operators acto on the <bra|, the normal scan order and
      (let ((fmt-i (mkstr "G1E_~aI(g~a, g~a, i_l+~a, j_l);~%"))
            (fmt-op (mkstr "G1E_~aJ(g~a, g~a, i_l+" i-len ", j_l+~a);
G1E_~aI(g~a, g~a, i_l+" i-len ", j_l+~a);
n = envs->g_size * 3;
for (ix = 0; ix < n; ix++) {g~a[ix] += g~a[ix];}~%"))
            (fmt-j (mkstr "G1E_~aJ(g~a, g~a, i_l+" i-len ", j_l+~a);~%")))
        (dump-combo-braket fout fmt-i fmt-op fmt-j i-rev op-rev j-rev 0))
;;; generate gout
      (dump-s-1e fout tot-bits)
;;; dump result of eval-int
      (setf goutinc (gen-c-block fout "gout[~a] +=" (last1 raw-script)))
      (format fout "gout += ~a;~%}}~%" goutinc)
;;; generate function int1e
      (format fout "int ~a(double *opij, const int *shls,
const int *atm, const int natm,
const int *bas, const int nbas, const double *env) {~%" intname)
      (format fout "int ng[] = {~d, ~d, 0, 0, ~d, ~d, 0, ~d};~%"
              i-len (+ op-len j-len) tot-bits
              (if (eql sf 'sf) 1 4)
              (if (eql sf 'sf) goutinc (/ goutinc 4)))
;;; determine factor
      (when (member 'g raw-infix)
        (format fout "const int i_sh = shls[0];
const int j_sh = shls[1];
const int i_l = bas(ANG_OF, i_sh);
const int j_l = bas(ANG_OF, j_sh);")
        (format fout "if (bas(ATOM_OF, i_sh) == bas(ATOM_OF, j_sh)) {~%")
        (if (eql sp 'spinor)
           (format fout "int ip = CINTlen_spinor(i_sh, bas) * bas(NCTR_OF,i_sh);
int jp = CINTlen_spinor(j_sh, bas) * bas(NCTR_OF,j_sh);
CINTdset0(ip * jp * OF_CMPLX * ng[TENSOR], opij);~%")
           (format fout "int ip = (i_l * 2 + 1) * bas(NCTR_OF,i_sh);
int jp = (j_l * 2 + 1) * bas(NCTR_OF,j_sh);
CINTdset0(ip * jp * ng[TENSOR], opij);~%"))
        (format fout "return 0; }~%"))
;;; determine function caller
      (let ((intdrv (cond ((member 'nuc raw-infix) "CINT1e_nuc_drv")
                          ((or (member 'rinv raw-infix)
                               (member 'nabla-rinv raw-infix))
                           "CINT1e_rinv_drv")
                          (t "CINT1e_drv")))
            (rfac (factor-of raw-infix))
            (c2sor (name-c2sor "1e" sp sf ts)))
        (format fout "CINTEnvVars envs;
CINTinit_int1e_EnvVars(&envs, ng, shls, atm, natm, bas, nbas, env);~%")
        (format fout "envs.f_gout = &CINTgout1e_~a;~%" intname)
        (format fout "return ~a(opij, &envs, ~a, ~a); }~%C2F_(~a)~%"
                intdrv rfac c2sor intname)))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun dump-declare-giao-ijkl (fout opi opj opk opl)
  (let ((n-ij (count 'g (append opi opj)))
        (n-kl (count 'g (append opk opl))))
    (when (> n-ij 0)
      (format fout "double rirj[3];~%")
      (format fout "rirj[0] = ri[0] - rj[0];~%" )
      (format fout "rirj[1] = ri[1] - rj[1];~%" )
      (format fout "rirj[2] = ri[2] - rj[2];~%" ))
    (when (> n-kl 0)
      (format fout "double rkrl[3];~%")
      (format fout "rkrl[0] = rk[0] - rl[0];~%" )
      (format fout "rkrl[1] = rk[1] - rl[1];~%" )
      (format fout "rkrl[2] = rk[2] - rl[2];~%" ))
    (when (> (+ n-ij n-kl) 0)
      (format fout "double c[~a];~%" (expt 3 (+ n-ij n-kl)))
      (loop
        for i upto (1- (expt 3 (+ n-ij n-kl))) do
        (format fout "c[~a] = 1" i)
        (loop
          for j from (+ n-ij n-kl -1) downto n-kl
          and res = i then (multiple-value-bind (int res) (floor res (expt 3 j))
                             (format fout " * rirj[~a]" int)
                             res))
        (loop
          for j from (1- n-kl) downto 0
          and res = (nth-value 1 (floor i (expt 3 n-kl)))
                    then (multiple-value-bind (int res) (floor res (expt 3 j))
                           (format fout " * rkrl[~a]" int)
                           res))
        (format fout ";~%")))))

(defun dump-s-2e (fout n)
  (flet ((dump-s-for-nroots (nroots)
           (loop
             for i upto (1- (expt 3 n)) do
             (let* ((ybin (dec-to-ybin i))
                    (zbin (dec-to-zbin i))
                    (xbin (- (ash 1 n) 1 ybin zbin)))
               (format fout "s[~a] = " i)
               (loop
                 for k upto (1- nroots) do
                 (format fout "+ g~a[ix+~a]*g~a[iy+~a]*g~a[iz+~a]"
                         xbin k ybin k zbin k))
               (format fout ";~%"))))
         (dump-s-loop ()
           (loop
             for i upto (1- (expt 3 n)) do
             (let* ((ybin (dec-to-ybin i))
                    (zbin (dec-to-zbin i))
                    (xbin (- (ash 1 n) 1 ybin zbin)))
               (format fout "s[~a] += g~a[ix+i] * g~a[iy+i] * g~a[iz+i];~%"
                       i xbin ybin zbin))))) ; end do i = 1, envs->nrys_roots
    (format fout "for (n = 0; n < nf; n++, idx+=3) {
ix = idx[0];
iy = idx[1];
iz = idx[2];~%")
    (if (< n 3) ; we don't want to torture compiler
      (progn
        (format fout "switch (envs->nrys_roots) {~%")
        (format fout "case 1:~%")
        (dump-s-for-nroots 1)
        (format fout "break;~%" )
        (format fout "case 2:~%")
        (dump-s-for-nroots 2)
        (format fout "break;~%" )
        (format fout "case 3:~%")
        (dump-s-for-nroots 3)
        (format fout "break;~%" )
        (format fout "case 4:~%")
        (dump-s-for-nroots 4)
        (format fout "break;~%" )
        (format fout "case 5:~%")
        (dump-s-for-nroots 5)
        (format fout "break;~%" )
        (format fout "case 6:~%")
        (dump-s-for-nroots 6)
        (format fout "break;~%" )
        (format fout "case 7:~%" )
        (dump-s-for-nroots 7)
        (format fout "break;~%" )
        (format fout "case 8:~%" )
        (dump-s-for-nroots 8)
        (format fout "break;~%" )
        (format fout "default:
CINTdset0(~a, s);
for (i = 0; i < envs->nrys_roots; i++) {~%" (expt 3 n))
        (dump-s-loop)
        (format fout "} break;}~%")) ; else
      (progn
        (format fout "CINTdset0(~a, s);
for (i = 0; i < envs->nrys_roots; i++) {~%" (expt 3 n))
        (dump-s-loop)
        (format fout "}~%")))))

(defun dump-s-2e-sse (fout n)
  (labels ((dump-s-for-nroots (nroots)
             (loop
               for i upto (1- (expt 3 n)) do
               (let* ((ybin (dec-to-ybin i))
                      (zbin (dec-to-zbin i))
                      (xbin (- (ash 1 n) 1 ybin zbin)))
                 (format fout "s[~a] = " i)
                 (loop
                   for k upto (1- nroots) do
                   (format fout "+ g~a[ix+~a]*g~a[iy+~a]*g~a[iz+~a]"
                           xbin k ybin k zbin k))
                 (format fout ";~%"))))
             (root2-sse (i xbin ybin zbin)
               (format fout "r0 = _mm_load_pd(g~d+ix  );~%" xbin)
               (format fout "r1 = _mm_load_pd(g~d+iy  );~%" ybin)
               (format fout "r0 = _mm_mul_pd(r0, r1);~%")
               (format fout "r1 = _mm_load_pd(g~d+iz  );~%" zbin)
               (format fout "r0 = _mm_mul_pd(r0, r1);~%")
               (format fout "r0 = _mm_hadd_pd(r0, r0);~%")
               (format fout "_mm_storeh_pd(s+~d, r0);~%" i))
             (root3-sse (i xbin ybin zbin)
               (root2-sse i xbin ybin zbin)
               (format fout "s[~d] += g~d[ix+2] * g~d[iy+2] * g~d[iz+2];~%"
                       i xbin ybin zbin))
             (root4-sse (i xbin ybin zbin)
               (format fout "r0 = _mm_load_pd(g~d+ix  );~%" xbin)
               (format fout "r1 = _mm_load_pd(g~d+iy  );~%" ybin)
               (format fout "r0 = _mm_mul_pd(r0, r1);~%")
               (format fout "r1 = _mm_load_pd(g~d+iz  );~%" zbin)
               (format fout "r0 = _mm_mul_pd(r0, r1);~%")
               (format fout "r2 = _mm_load_pd(g~d+ix+2);~%" xbin)
               (format fout "r1 = _mm_load_pd(g~d+iy+2);~%" ybin)
               (format fout "r2 = _mm_mul_pd(r2, r1);~%")
               (format fout "r1 = _mm_load_pd(g~d+iz+2);~%" zbin)
               (format fout "r2 = _mm_mul_pd(r2, r1);~%")
               (format fout "r0 = _mm_add_pd(r0, r2);~%")
               (format fout "r0 = _mm_hadd_pd(r0, r0);~%")
               (format fout "_mm_storeh_pd(s+~d, r0);~%" i))
             (root5-sse (i xbin ybin zbin)
               (root4-sse i xbin ybin zbin)
               (format fout "s[~d] += g~d[ix+4] * g~d[iy+4] * g~d[iz+4];~%"
                       i xbin ybin zbin))
             (root6-sse (i xbin ybin zbin)
               (format fout "r0 = _mm_load_pd(g~d+ix  );~%" xbin)
               (format fout "r1 = _mm_load_pd(g~d+iy  );~%" ybin)
               (format fout "r0 = _mm_mul_pd(r0, r1);~%")
               (format fout "r1 = _mm_load_pd(g~d+iz  );~%" zbin)
               (format fout "r0 = _mm_mul_pd(r0, r1);~%")
               (format fout "r2 = _mm_load_pd(g~d+ix+2);~%" xbin)
               (format fout "r1 = _mm_load_pd(g~d+iy+2);~%" ybin)
               (format fout "r2 = _mm_mul_pd(r2, r1);~%")
               (format fout "r1 = _mm_load_pd(g~d+iz+2);~%" zbin)
               (format fout "r2 = _mm_mul_pd(r2, r1);~%")
               (format fout "r0 = _mm_add_pd(r0, r2);~%")
               (format fout "r2 = _mm_load_pd(g~d+ix+4);~%" xbin)
               (format fout "r1 = _mm_load_pd(g~d+iy+4);~%" ybin)
               (format fout "r2 = _mm_mul_pd(r2, r1);~%")
               (format fout "r1 = _mm_load_pd(g~d+iz+4);~%" zbin)
               (format fout "r2 = _mm_mul_pd(r2, r1);~%")
               (format fout "r0 = _mm_add_pd(r0, r2);~%")
               (format fout "r0 = _mm_hadd_pd(r0, r0);~%")
               (format fout "_mm_storeh_pd(s+~d, r0);~%" i))
             (root7-sse (i xbin ybin zbin)
               (root6-sse i xbin ybin zbin)
               (format fout "s[~d] += g~d[ix+6] * g~d[iy+6] * g~d[iz+6];~%"
                       i xbin ybin zbin))
             (root8-sse (i xbin ybin zbin)
               (format fout "r0 = _mm_load_pd(g~d+ix  );~%" xbin)
               (format fout "r1 = _mm_load_pd(g~d+iy  );~%" ybin)
               (format fout "r0 = _mm_mul_pd(r0, r1);~%")
               (format fout "r1 = _mm_load_pd(g~d+iz  );~%" zbin)
               (format fout "r0 = _mm_mul_pd(r0, r1);~%")
               (format fout "r2 = _mm_load_pd(g~d+ix+2);~%" xbin)
               (format fout "r1 = _mm_load_pd(g~d+iy+2);~%" ybin)
               (format fout "r2 = _mm_mul_pd(r2, r1);~%")
               (format fout "r1 = _mm_load_pd(g~d+iz+2);~%" zbin)
               (format fout "r2 = _mm_mul_pd(r2, r1);~%")
               (format fout "r0 = _mm_add_pd(r0, r2);~%")
               (format fout "r2 = _mm_load_pd(g~d+ix+4);~%" xbin)
               (format fout "r1 = _mm_load_pd(g~d+iy+4);~%" ybin)
               (format fout "r2 = _mm_mul_pd(r2, r1);~%")
               (format fout "r1 = _mm_load_pd(g~d+iz+4);~%" zbin)
               (format fout "r2 = _mm_mul_pd(r2, r1);~%")
               (format fout "r0 = _mm_add_pd(r0, r2);~%")
               (format fout "r2 = _mm_load_pd(g~d+ix+6);~%" xbin)
               (format fout "r1 = _mm_load_pd(g~d+iy+6);~%" ybin)
               (format fout "r2 = _mm_mul_pd(r2, r1);~%")
               (format fout "r1 = _mm_load_pd(g~d+iz+6);~%" zbin)
               (format fout "r2 = _mm_mul_pd(r2, r1);~%")
               (format fout "r0 = _mm_add_pd(r0, r2);~%")
               (format fout "r0 = _mm_hadd_pd(r0, r0);~%")
               (format fout "_mm_storeh_pd(s+~d, r0);~%" i))
             (dump-s-for-sse (nroots)
               (loop
                 for i upto (1- (expt 3 n)) do
                 (let* ((ybin (dec-to-ybin i))
                        (zbin (dec-to-zbin i))
                        (xbin (- (ash 1 n) 1 ybin zbin)))
                   (case nroots
                     (2 (root2-sse i xbin ybin zbin))
                     (3 (root3-sse i xbin ybin zbin))
                     (4 (root4-sse i xbin ybin zbin))
                     (5 (root5-sse i xbin ybin zbin))
                     (6 (root6-sse i xbin ybin zbin))
                     (7 (root7-sse i xbin ybin zbin))))))
             (dump-s-loop-sse-since (start_id)
               (loop
                 for i upto (1- (expt 3 n)) do
                 (let* ((ybin (dec-to-ybin i))
                        (zbin (dec-to-zbin i))
                        (xbin (- (ash 1 n) 1 ybin zbin)))
                   (case start_id
                     (2 (root2-sse i xbin ybin zbin))
                     (4 (root4-sse i xbin ybin zbin))
                     (6 (root6-sse i xbin ybin zbin))
                     (8 (root8-sse i xbin ybin zbin)))
                   (format fout "for (i = ~d; i < envs->nrys_roots; i++) {~%" start_id)
                   (format fout "s[~a] += g~a[ix+i] * g~a[iy+i] * g~a[iz+i];}~%"
                           i xbin ybin zbin))))
             (dump-s-loop ()
               (loop
                 for i upto (1- (expt 3 n)) do
                 (let* ((ybin (dec-to-ybin i))
                        (zbin (dec-to-zbin i))
                        (xbin (- (ash 1 n) 1 ybin zbin)))
                   (format fout "s[~a] += g~a[ix+i] * g~a[iy+i] * g~a[iz+i];~%"
                           i xbin ybin zbin)))))
  (format fout "__m128d r0, r1, r2, r3;
for (n = 0; n < nf; n++, idx+=3) {
ix = idx[0];
iy = idx[1];
iz = idx[2];~%")
  (if (< n 3) ; we don't want to torture compiler
    (progn
      (format fout "switch (envs->nrys_roots) {~%")
      (format fout "case 1:~%")
      (dump-s-for-nroots 1)
      (format fout "break;~%" )
      (format fout "case 2:~%")
      (dump-s-for-sse 2)
      (format fout "break;~%" )
      (format fout "case 3:~%")
      (dump-s-for-sse 3)
      (format fout "break;~%" )
      (format fout "case 4:~%")
      (dump-s-for-sse 4)
      (format fout "break;~%" )
      (format fout "case 5:~%")
      (dump-s-for-sse 5)
      (format fout "break;~%" )
      (format fout "case 6:~%")
      (dump-s-for-sse 6)
      (format fout "break;~%" )
      (format fout "case 7:~%" )
      (dump-s-for-sse 7)
      (format fout "break;~%" )
      (format fout "default:~%")
      (dump-s-loop-sse-since 8)
      (format fout "break;}~%")) ; else
    (progn
      (format fout "CINTdset0(~a, s);
for (i = 0; i < envs->nrys_roots; i++) {~%" (expt 3 n))
      (dump-s-loop)
      (format fout "}~%")))))

(defun dump-s-2e-greduce (fout n)
  (if (eql n 1)
    (dump-s-2e-sse fout 1)
    (progn
  (format fout "for (n = 0; n < nf; n++, idx+=3) {~%")
  (case n
    (1 (format fout "CINTreduce_gxyz1(s, envs->nrys_roots, idx, g0, g1);~%"))
    (2 (format fout "CINTreduce_gxyz2(s, envs->nrys_roots, idx, g0, g1, g2, g3);~%"))
    (3 (format fout "CINTreduce_gxyz3(s, envs->nrys_roots, idx, g0, g1, g2, g3,
g4, g5, g6, g7);~%"))
    (4 (format fout "CINTreduce_gxyz4(s, envs->nrys_roots, idx, g0, g1, g2, g3,
g4, g5, g6, g7, g8, g9, g10, g11, g12, g13, g14, g15);~%"))
    (otherwise (format fout "CINTdset0(~a, s);
ix = idx[0];
iy = idx[1];
iz = idx[2];
for (i = 0; i < envs->nrys_roots; i++) {~%" (expt 3 n))
    (loop
      for i upto (1- (expt 3 n)) do
      (let* ((ybin (dec-to-ybin i))
             (zbin (dec-to-zbin i))
             (xbin (- (ash 1 n) 1 ybin zbin)))
        (format fout "s[~a] += g~a[ix+i] * g~a[iy+i] * g~a[iz+i];~%"
                i xbin ybin zbin)))
    (format fout "}~%"))))))

(defun gen-code-int2e (fout intname raw-infix &optional (sp 'spinor))
  (destructuring-bind (op bra-i ket-j bra-k ket-l)
    (split-int-expression raw-infix)
    (let* ((i-rev (effect-keys bra-i))
           (j-rev (reverse (effect-keys ket-j)))
           (k-rev (effect-keys bra-k))
           (l-rev (reverse (effect-keys ket-l)))
           (op-rev (reverse (effect-keys op)))
           (i-len (length i-rev))
           (j-len (length j-rev))
           (k-len (length k-rev))
           (l-len (length l-rev))
           (op-len (length op-rev))
           (tot-bits (+ i-len j-len op-len k-len l-len))
           (raw-script (eval-int raw-infix))
           (ts1 (car raw-script))
           (sf1 (cadr raw-script))
           (ts2 (caddr raw-script))
           (sf2 (cadddr raw-script))
           (goutinc))
      (format fout "/* <~{~a ~}k ~{~a ~}i|~{~a ~}|~{~a ~}j ~{~a ~}l> : i,j\in electron 1; k,l\in electron 2~%"
              bra-k bra-i op ket-j ket-l)
      (format fout " * = (~{~a ~}i ~{~a ~}j|~{~a ~}|~{~a ~}k ~{~a ~}l) */~%"
              bra-i ket-j op bra-k ket-l)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; generate function gout2e
      (format fout "static void CINTgout2e_~a(double *g,
double *gout, const int *idx, const CINTEnvVars *envs, int gout_empty) {~%" intname)
      (format fout "const double *env = envs->env;
const int nf = envs->nf;
const int i_l = envs->i_l;
const int j_l = envs->j_l;
const int k_l = envs->k_l;
const int l_l = envs->l_l;
const double *ri = envs->ri;
const double *rj = envs->rj;
const double *rk = envs->rk;
const double *rl = envs->rl;
int ix, iy, iz, i, n;
double *g0 = g;~%")
      (loop
        for i in (range (ash 1 tot-bits)) do
        (format fout "double *g~a = g~a + envs->g_size * 3;~%" (1+ i) i))
      (format fout "double s[~a];~%" (expt 3 tot-bits))
      (dump-declare-dri-for-rc fout bra-i "i")
      (dump-declare-dri-for-rc fout ket-j "j")
      (dump-declare-dri-for-rc fout bra-k "k")
      (dump-declare-dri-for-rc fout ket-l "l")
      (dump-declare-giao-ijkl fout bra-i ket-j bra-k ket-l)
;;; generate g_(bin)
      (let ((fmt-k (mkstr "G2E_~aK(g~a, g~a, i_l+" i-len ", j_l+" j-len
                          ", k_l+~a, l_l);~%"))
            (fmt-op "")
            (fmt-l (mkstr "G2E_~aL(g~a, g~a, i_l+" i-len ", j_l+" j-len
                          ", k_l+" k-len ", l_l+~a);~%")))
        (dump-combo-braket fout fmt-k fmt-op fmt-l k-rev op-rev l-rev 0))
      (let ((fmt-i (mkstr "G2E_~aI(g~a, g~a, i_l+~a, j_l, k_l, l_l);~%"))
            (fmt-op (mkstr "G2E_~aJ(g~a, g~a, i_l+" i-len ", j_l+~a, k_l, l_l);
G2E_~aI(g~a, g~a, i_l+" i-len ", j_l+~a, k_l, l_l);
n = envs->g_size * 3;
for (ix = 0; ix < n; ix++) {g~a[ix] += g~a[ix];}~%"))
            (fmt-j (mkstr "G2E_~aJ(g~a, g~a, i_l+" i-len ", j_l+~a, k_l, l_l);~%")))
        (dump-combo-braket fout fmt-i fmt-op fmt-j i-rev op-rev j-rev (+ k-len l-len)))
;;; generate gout
      ;(dump-s-2e fout tot-bits)
      (dump-s-2e-sse fout tot-bits)
;;; dump result of eval-int
      (format fout "if (gout_empty) {~%")
      (setf goutinc (gen-c-block fout "gout[~a] =" (last1 raw-script)))
      (format fout "gout += ~a;~%} else {~%" goutinc)
      (setf goutinc (gen-c-block fout "gout[~a] +=" (last1 raw-script)))
      (format fout "gout += ~a;~%}}}~%" goutinc)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; generate optimizer for function int2e
      (format fout "void ~a_optimizer(CINTOpt **opt, const int *atm, const int natm,
const int *bas, const int nbas, const double *env) {~%" intname)
      (format fout "int ng[] = {~d, ~d, ~d, ~d, 0, 0, 0, 0};~%"
              i-len j-len k-len (+ op-len l-len))
      (format fout "CINTuse_all_optimizer(opt, ng, atm, natm, bas, nbas, env);~%}~%")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; generate function int2e
      (format fout "int ~a(double *opkijl, const int *shls,
const int *atm, const int natm,
const int *bas, const int nbas, const double *env, CINTOpt *opt) {~%" intname)
      (format fout "int ng[] = {~d, ~d, ~d, ~d, ~d, ~d, ~d, ~d};~%"
              i-len j-len k-len (+ op-len l-len) tot-bits
              (if (eql sf1 'sf) 1 4) (if (eql sf2 'sf) 1 4)
              (cond ((and (eql sf1 'sf) (eql sf2 'sf)) goutinc)
                    ((and (eql sf1 'si) (eql sf2 'si)) (/ goutinc 16))
                    (t (/ goutinc 4))))
;;; determine factor
      (when (member 'g raw-infix)
        (format fout "const int i_sh = shls[0];
const int j_sh = shls[1];
const int k_sh = shls[2];
const int l_sh = shls[3];~%")
        (let ((set0sph "int ip = (bas(ANG_OF,i_sh) * 2 + 1) * bas(NCTR_OF,i_sh);
int jp = (bas(ANG_OF,j_sh) * 2 + 1) * bas(NCTR_OF,j_sh);
int kp = (bas(ANG_OF,k_sh) * 2 + 1) * bas(NCTR_OF,k_sh);
int lp = (bas(ANG_OF,l_sh) * 2 + 1) * bas(NCTR_OF,l_sh);
CINTdset0(kp * ip * jp * lp * ng[TENSOR], opkijl);")
              (set0spin "int ip = CINTlen_spinor(i_sh, bas) * bas(NCTR_OF,i_sh);
int jp = CINTlen_spinor(j_sh, bas) * bas(NCTR_OF,j_sh);
int kp = CINTlen_spinor(k_sh, bas) * bas(NCTR_OF,k_sh);
int lp = CINTlen_spinor(l_sh, bas) * bas(NCTR_OF,l_sh);
CINTdset0(kp * ip * jp * lp * OF_CMPLX * ng[TENSOR], opkijl);"))
        (when (or (member 'g bra-i) (member 'g ket-j))
          (format fout "if (bas(ATOM_OF, i_sh) == bas(ATOM_OF, j_sh)) {
~a~%return 0; }~%" (if (eql sp 'spinor) set0spin set0sph)))
        (when (or (member 'g bra-k) (member 'g ket-l))
          (format fout "if (bas(ATOM_OF, k_sh) == bas(ATOM_OF, l_sh)) {
~a~%return 0; }~%" (if (eql sp 'spinor) set0spin set0sph)))))
;;; initialize CINTEnvVars
      (format fout "CINTEnvVars envs;
CINTinit_int2e_EnvVars(&envs, ng, shls, atm, natm, bas, nbas, env);~%")
      (format fout "envs.f_gout = &CINTgout2e_~a;~%" intname)
      (format fout "envs.common_factor *= ~a;~%" (factor-of raw-infix))
;;; determine function caller
      (cond ((eql sp 'spinor)
             (format fout "return CINT2e_spinor_drv(opkijl, &envs, opt, ~a, ~a);~%}~%"
                     (name-c2sor "2e1" sp sf1 ts1)
                     (name-c2sor "2e2" sp sf2 ts2)))
            ((eql sp 'spheric)
             (format fout "return CINT2e_spheric_drv(opkijl, &envs, opt);~%}~%"))
            ((eql sp 'cart)
             (format fout "return CINT2e_cart_drv(opkijl, &envs, opt);~%}~%")))
      (format fout "OPTIMIZER2F_(~a_optimizer);~%C2Fo_(~a)~%"
              intname intname))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun gen-cint (filename sp &rest items)
  "sp can be one of 'spinor 'spheric 'cart"
  (if (not (member sp '(spinor spheric cart)))
    (error "gen-cint: unknown ~a . sp can be one of 'spinor 'spheric 'cart" sp))
  (with-open-file (fout (mkstr filename)
                        :direction :output :if-exists :supersede)
    (dump-header fout)
    (flet ((gen-code (item)
      (let ((intname (mkstr (car item)))
            (raw-infix (cadr item)))
        (if (one-electron-int? raw-infix)
          (gen-code-int1e fout intname raw-infix sp)
          (gen-code-int2e fout intname raw-infix sp)))))
      (mapcar #'gen-code items))))

; gcl -load sigma.o -batch -eval "( .. )"

;; vim: ft=lisp
