/*
 * Qints is a general GTO integral library for computational chemistry
 * Copyright (C) 2014- Qiming Sun <osirpt.sun@gmail.com>
 *
 * This file is part of Qints.
 *
 * Qints is free software: you can redistribute it and/or modify
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
 * Parameters and function prototypes for libcint.
 */

#cmakedefine I8
#ifdef I8
#include <stdint.h>
#define FINT int64_t
#else
#define FINT int
#endif

#define PTR_LIGHT_SPEED         0
#define PTR_COMMON_ORIG         1
#define PTR_RINV_ORIG           4
#define PTR_RINV_ZETA           7
#define PTR_ENV_START           20

// slots of atm
#define CHARGE_OF       0
#define PTR_COORD       1
#define NUC_MOD_OF      2
#define PTR_ZETA        3
#define RESERVE_ATMLOT1 4
#define RESERVE_ATMLOT2 5
#define ATM_SLOTS       6


// slots of bas
#define ATOM_OF         0
#define ANG_OF          1
#define NPRIM_OF        2
#define NCTR_OF         3
#define KAPPA_OF        4
#define PTR_EXP         5
#define PTR_COEFF       6
#define RESERVE_BASLOT  7
#define BAS_SLOTS       8

// slots of gout
#define POSX            0
#define POSY            1
#define POSZ            2
#define POS1            3
#define POSXX           0
#define POSYX           1
#define POSZX           2
#define POS1X           3
#define POSXY           4
#define POSYY           5
#define POSZY           6
#define POS1Y           7
#define POSXZ           8
#define POSYZ           9
#define POSZZ           10
#define POS1Z           11
#define POSX1           12
#define POSY1           13
#define POSZ1           14
#define POS11           15

// tensor
#define TSRX        0
#define TSRY        1
#define TSRZ        2
#define TSRXX       0
#define TSRXY       1
#define TSRXZ       2
#define TSRYX       3
#define TSRYY       4
#define TSRYZ       5
#define TSRZX       6
#define TSRZY       7
#define TSRZZ       8

// some other boundaries
#define ANG_MAX         15 // l = 0..7 .. 14
#define POINT_NUC       1
#define GAUSSIAN_NUC    2

#define bas(SLOT,I)     bas[BAS_SLOTS * (I) + (SLOT)]
#define atm(SLOT,I)     atm[ATM_SLOTS * (I) + (SLOT)]

#if !defined HAVE_DEFINED_CINTOPT_H
#define HAVE_DEFINED_CINTOPT_H
typedef struct {
    FINT **index_xyz_array; // ANG_MAX**4 pointers to index_xyz
    FINT *prim_offset;
    FINT *non0ctr;
    FINT **non0idx;
    double **non0coeff;
    double **expij;
    double **rij;
    FINT **cceij;
    FINT tot_prim;
} CINTOpt;
#endif

FINT CINTlen_cart(const FINT l);
FINT CINTlen_spinor(const FINT bas_id, const FINT *bas);

FINT CINTcgtos_cart(const FINT bas_id, const FINT *bas);
FINT CINTcgtos_spheric(const FINT bas_id, const FINT *bas);
FINT CINTcgtos_spinor(const FINT bas_id, const FINT *bas);
FINT CINTcgto_cart(const FINT bas_id, const FINT *bas);
FINT CINTcgto_spheric(const FINT bas_id, const FINT *bas);
FINT CINTcgto_spinor(const FINT bas_id, const FINT *bas);

FINT CINTtot_pgto_spheric(const FINT *bas, const FINT nbas);
FINT CINTtot_pgto_spinor(const FINT *bas, const FINT nbas);

FINT CINTtot_cgto_cart(const FINT *bas, const FINT nbas);
FINT CINTtot_cgto_spheric(const FINT *bas, const FINT nbas);
FINT CINTtot_cgto_spinor(const FINT *bas, const FINT nbas);

void CINTshells_cart_offset(FINT ao_loc[], const FINT *bas, const FINT nbas);
void CINTshells_spheric_offset(FINT ao_loc[], const FINT *bas, const FINT nbas);
void CINTshells_spinor_offset(FINT ao_loc[], const FINT *bas, const FINT nbas);

double *CINTc2s_bra_sph(double *sph, FINT nket, double *cart, FINT l);
double *CINTc2s_ket_sph(double *sph, FINT nket, double *cart, FINT l);


double CINTgto_norm(FINT n, double a);


void CINTinit_2e_optimizer(CINTOpt **opt, const FINT *atm, const FINT natm,
                           const FINT *bas, const FINT nbas, const double *env);
void CINTinit_optimizer(CINTOpt **opt, const FINT *atm, const FINT natm,
                        const FINT *bas, const FINT nbas, const double *env);
void CINTdel_2e_optimizer(CINTOpt **opt);
void CINTdel_optimizer(CINTOpt **opt);


FINT cint2e_cart(double *opijkl, const FINT *shls,
                const FINT *atm, const FINT natm,
                const FINT *bas, const FINT nbas, const double *env,
                const CINTOpt *opt);
void cint2e_cart_optimizer(CINTOpt **opt, const FINT *atm, const FINT natm,
                           const FINT *bas, const FINT nbas, const double *env);
FINT cint2e_sph(double *opijkl, const FINT *shls,
               const FINT *atm, const FINT natm,
               const FINT *bas, const FINT nbas, const double *env,
               const CINTOpt *opt);
void cint2e_sph_optimizer(CINTOpt **opt, const FINT *atm, const FINT natm,
                          const FINT *bas, const FINT nbas, const double *env);
FINT cint2e(double *opijkl, const FINT *shls,
           const FINT *atm, const FINT natm,
           const FINT *bas, const FINT nbas, const double *env,
           const CINTOpt *opt);
void cint2e_optimizer(CINTOpt **opt, const FINT *atm, const FINT natm,
                      const FINT *bas, const FINT nbas, const double *env);

