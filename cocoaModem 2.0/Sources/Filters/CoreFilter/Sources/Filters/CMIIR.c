//
//  CMIIR.c
//  Filter (CoreModem)
//
//  Created by Kok Chen on 
//	Ported from ModemFilter.c in cocoaModem, original file dated Thu Jun 03 2004.
	#include "Copyright.h"


#include "CMIIR.h"
#include "CMDSPWindow.h"
#include "CoreFilterTypes.h"
#include <math.h>
#include <time.h>

#define samplingRate CMFs

//  these are routines used to generate the filter coefficients that are used in cocoaModem.

//  IIR design adapted from applet by http://www.dsptutor.freeuk.com/


float filterGain( IIR *iir, float freq ) 
{
	double theta, s, c, sac, sas, sbc, sbs ;
	double g ;
	int k, order ;
	
	order = iir->order ;
	
	theta = CMPi*freq/iir->fN ;
	sac = sas = sbc = sbs = 0.0 ;
	for ( k = 0; k <= order; k++ ) {
		c = cos( k*theta ) ;
		s = sin( k*theta ) ;
		sac += c*iir->zero[k] ;
		sas += s*iir->zero[k] ;
		sbc += c*iir->pole[k] ;
		sbs += s*iir->pole[k] ;
	}
	g = sqrt( ( sac*sac + sas*sas )/( sbc*sbc + sbs*sbs ) ) ;

    return g;
}

//  poles and zeros from bilinear transform
void butterworth( IIR *iir ) 
{
    double f1, f4, f5 ;
    double tanw1, tansqw1 ;
	double t, a, re, im, b3 ;
	double aa, aR, aI, h1, h2, p1R, p2R, p1I, p2I ;
	double fR, fI, gR, gI, sR, sI ;
	int k, n, m, m1, ir, n1, n2 ;
	
	n = iir->order ;
    for( k = 0; k <= n; k++ ) iir->pReal[k] = iir->pImag[k] = 0 ;

    if ( iir->filterType == BP ) n = n/2 ;
    ir = n % 2;
    n1 = n + ir;
    n2 = ( 3*n + ir )/2 - 1 ;
	switch ( iir->filterType ) {
	case LP: 
		f1 = iir->fp2 ;
		break;
	case HP: 
		f1 = iir->fN - iir->fp1 ;
		break;
	case BP: 
		f1 = iir->fp2 - iir->fp1 ; 
		break;
	default: 
		f1 = 0 ;
    }
    tanw1 = tan( 0.5*CMPi*f1/iir->fN ) ;
    tansqw1 = tanw1*tanw1 ;
    // low-pass poles
    a = 1.0 ;
	re = im = 1.0 ;
    for ( k = n1; k <= n2; k++ ) {
		t = 0.5*(2*k + 1 - ir)*CMPi/n ;
		b3 = 1.0 - 2.0*tanw1*cos(t) + tansqw1;
		re = ( 1.0 - tansqw1 )/b3;
		im = 2.0*tanw1*sin(t)/b3;

		m = 2*(n2 - k) + 1;
		iir->pReal[m+ir] = re ;
		iir->pImag[m+ir] = fabs( im ) ;
		iir->pReal[m+ir+1] = re ;
		iir->pImag[m+ir+1] = -fabs( im ) ;
    }
    if ( ( n&1 ) != 0 ) {
		re = ( 1.0 - tansqw1 )/( 1.0 + 2.0*tanw1+tansqw1 ) ;
		iir->pReal[1] = re ;
		iir->pImag[1] = 0 ;
    }
    switch ( iir->filterType ) {
	case LP:
		for ( m = 1; m <= n; m++ ) iir->z[m]= -1.0;
		break ;
	case HP:
        // low-pass to high-pass transformation
        for ( m = 1; m <= n; m++ ) {
			iir->pReal[m] = -iir->pReal[m];
			iir->z[m] = 1.0;
        }
        break;
	case BP:
        // low-pass to bandpass transformation
        for ( m = 1; m <= n; m++ ) {
			iir->z[m] =  1.0 ;
			iir->z[m+n] = -1.0 ;
        }
        f4 = 0.5*CMPi*iir->fp1/iir->fN ;
        f5 = 0.5*CMPi*iir->fp2/iir->fN ;

        aa = cos(f4 + f5)/cos(f5 - f4) ;

        for ( m1 = 0; m1 <= (iir->order - 1)/2; m1++ ) {
			m = 2*m1 + 1 ;
			aR = iir->pReal[m] ;
			aI = iir->pImag[m] ;
			if ( fabs(aI) < 0.0001 ) {
				h1 = 0.5*aa*( 1.0 + aR ) ;
				h2 = h1*h1 - aR ;
				if ( h2 > 0.0 ) {
					p1R = h1 + sqrt(h2) ;
					p2R = h1 - sqrt(h2) ;
					p1I = p2I = 0 ;
				}
				else {
					p1R = p2R = h1 ;
					p1I = sqrt( fabs(h2) ) ;
					p2I = -p1I ;
				}
			}
			else {
				fR = aa*0.5*(1.0 + aR);
				fI = aa*0.5*aI;
				gR = fR*fR - fI*fI - aR;
				gI = 2*fR*fI - aI;
				sR = sqrt( 0.5*fabs( gR+sqrt(gR*gR + gI*gI ) ) ) ;
				sI = gI/( 2.0*sR ) ;
				p1R = fR + sR ;
				p1I = fI + sI ;
				p2R = fR - sR ;
				p2I = fI - sI ;
			}
			iir->pReal[m] = p1R;
			iir->pReal[m+1] = p2R;
			iir->pImag[m] = p1I;
			iir->pImag[m+1] = p2I;
        }
        if ( ( n&1 ) != 0) {
			iir->pReal[2] = iir->pReal[n+1] ;
			iir->pImag[2] = iir->pImag[n+1] ;
        }
        for ( k = n; k >= 1; k-- ) {
			m = 2*k - 1 ;
			iir->pReal[m] = iir->pReal[m+1] = iir->pReal[k] ;
			iir->pImag[m+1] = -( iir->pImag[m] = fabs( iir->pImag[k] ) ) ;
        }
    }
}

//  for lpf and hp, specify bw only (cutoff)
//  filter gain is returned
float butterworthDesign( int order, int type, float bw, float fCenter, double *pole, double *zero )
{
	IIR iir ;
	double zerop[16], polep[16], r ;
	double alpha1, alpha2, beta1, beta2 ;
	int i, k, m, n, pairs, p ;

	iir.order = order ;
	iir.filterType = type ;
	iir.fN = samplingRate*0.5 ;
	
	switch ( type ) {
	case LP:
		iir.fp1 = 0.0 ;
		iir.fp2 = bw ;
		break ;
	case HP:
		iir.fp1 = bw ;
		iir.fp2 = iir.fN ;
		break ;
	default:
	case BP:
		r = ( bw +sqrt( bw*bw + 4.*fCenter*fCenter ) )/(2*fCenter ) ;
		iir.fp1 = fCenter/r ;
		iir.fp2 = fCenter*r ;
		break ;
	}
	
    butterworth( &iir ) ;

    pole[0]= zero[0]= 1 ;
    for ( i = 1; i <= order; i++ ) pole[i] = zero[i] = 0 ;

    k = 0;
    n = order ;
    pairs = n/2 ;
    if ( ( order&1 ) != 0 ) {
		// first subfilter is first order
		pole[1] = - iir.z[1];
		zero[1] = - iir.pReal[1];
		k = 1 ;
    }
    for ( p = 1; p <= pairs; p++ ) {
		m = 2*p - 1 + k;
		alpha1 = -( iir.z[m] + iir.z[m+1] ) ;
		alpha2 = iir.z[m]*iir.z[m+1] ;
		beta1 = - 2.0*iir.pReal[m] ;
		beta2 = iir.pReal[m]*iir.pReal[m] + iir.pImag[m]*iir.pImag[m] ;

		zerop[1] = zero[1] + alpha1*zero[0] ;
		polep[1] = pole[1] + beta1*pole[0] ;
		for ( i = 2; i <= n; i++ ) {
			zerop[i] = zero[i] + alpha1*zero[i-1] + alpha2*zero[i-2];
			polep[i] = pole[i] + beta1*pole[i-1] + beta2*pole[i-2];
		}
		for ( i = 1; i <= n; i++ ) {
			zero[i] = zerop[i] ;
			pole[i] = polep[i] ;
		}
    }
	iir.pole = pole ;
	iir.zero = zero ;
	
	switch ( type ) {
	case LP:
		return filterGain( &iir, 0.0 ) ;
	case HP:
		return filterGain( &iir, iir.fN ) ;
	}
	return filterGain( &iir, fCenter ) ;
}

float notchDesign( float bw, float fNotch, double *pole, double *zero )
{
	float w0, Bw ;
	double alpha, beta, t ;
	
	w0 = 2.0*CMPi*fNotch/samplingRate ;
	Bw = 2.0*CMPi*bw/samplingRate ;
	t = tan( Bw*0.5 ) ;
	
	alpha = ( 1.- t )/( 1.+t ) ;
	beta = cos( w0 ) ;
	
	zero[0] = 1.0 ;
	zero[1] = -2.0*beta ;
	zero[2] = 1.0 ;
	pole[0] = 1.0 ;
	pole[1] = -2.*beta*(1.+alpha) ;
	pole[2] = alpha ;
	
	return 2./( 1+ alpha ) ;
}

