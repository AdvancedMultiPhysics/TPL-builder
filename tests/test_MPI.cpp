#include <mpi.h>
#include <stdio.h>


int main( int argc, char** argv )
{
    // Initialize the MPI environment
    MPI_Init( &argc, &argv );

    // Get the number of processes
    int size;
    MPI_Comm_size( MPI_COMM_WORLD, &size );

    // Get the rank of the process
    int rank;
    MPI_Comm_rank( MPI_COMM_WORLD, &rank );

    // Get the name of the processor
    char name[MPI_MAX_PROCESSOR_NAME];
    int name_len;
    MPI_Get_processor_name( name, &name_len );

    // Print off a hello world message
    printf( "Hello world from processor %s, rank %d out of %d processors\n", name, rank, size );

    // Call barrier
    MPI_Barrier( MPI_COMM_WORLD );
    if ( rank == 0 ) printf( "Called MPI_Barrier\n" );

    // Finalize the MPI environment.
    MPI_Finalize();
    printf( "Rank %i finished\n", rank );
    return 0;
}
