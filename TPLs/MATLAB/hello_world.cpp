#include "mex.h"


void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{
    mexPrintf( "Hello World\n" );
    plhs[0] = mxCreateDoubleScalar(17);
}
