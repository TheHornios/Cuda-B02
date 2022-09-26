/**
* ARQUITECTURA DE COMPUTADORES
* 2º Grado en Ingenieria Informatica
*
* Básico 2
*
* Alumno: Rodrigo Pascual Arnaiz 
* Fecha: 26/09/2022
*
*/

///////////////////////////////////////////////////////////////////////////
// includes
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <cuda_runtime.h>
#include <device_launch_parameters.h> 

///////////////////////////////////////////////////////////////////////////
// defines


///////////////////////////////////////////////////////////////////////////
// declaracion de funciones
// HOST: funcion llamada desde el host y ejecutada en el host

/**
* Funcion: propiedadesDispositivo
* Objetivo: Mustra las propiedades del dispositvo, esta funcion
*   es ejecutada llamada y ejecutada desde el host
*
* Param: INT id_dispositivo -> ID del dispotivo
* Return: void
*/
__host__ void propiedadesDispositivo(int id_dispositivo, int &cantidad_computo )
{
    cudaDeviceProp deviceProp;
    cudaGetDeviceProperties(&deviceProp, id_dispositivo);

    // calculo del numero de cores (SP)
    int cuda_cores = 0;
    int multi_processor_count = deviceProp.multiProcessorCount;
    int major = deviceProp.major;
    cantidad_computo = major;
    int minor = deviceProp.minor;


    switch (major)
    {
    case 1:
        //TESLA
        cuda_cores = 8;
        break;
    case 2:
        //FERMI
        if (minor == 0)
            cuda_cores = 32;
        else
            cuda_cores = 48;
        break;
    case 3:
        //KEPLER
        cuda_cores = 192;
        break;
    case 5:
        //MAXWELL
        cuda_cores = 128;
        break;
    case 6:
        //PASCAL
        cuda_cores = 64;
        break;
    case 7:
        //VOLTA
        cuda_cores = 64;
        break;
    case 8:
        //AMPERE
        cuda_cores = 128;
        break;
    default:
        //DESCONOCIDA
        cuda_cores = 0;
    }

    if (cuda_cores == 0)
    {
        printf("!!!!!dispositivo desconocido!!!!!\n");
    }
    // presentacion de propiedades
    printf("***************************************************\n");
    printf("DISPOSIRIVO %d: %s\n", id_dispositivo, deviceProp.name);
    printf("***************************************************\n");
    printf("> Capacidad de Computo \t\t\t: %d.%d\n", major, minor);
    printf("> N. de MultiProcesadores \t\t: %d \n", multi_processor_count);
    printf("> N. de CUDA Cores (%dx%d) \t\t: %d \n", cuda_cores, multi_processor_count, cuda_cores * multi_processor_count);
    printf("> Memoria Global (total) \t\t: %zu MiB\n", deviceProp.totalGlobalMem / (1 << 20));
    printf("> Memoria Compartida (por bloque) \t: %zu KiB\n", deviceProp.sharedMemPerBlock /
        (1 << 10));
    printf("> Memoria Constante (total) \t\t: %zu KiB\n", deviceProp.totalConstMem / (1 << 10));
    printf("***************************************************\n");
}

/**
* Funcion: rellenarVectorHst
* Objetivo: Funcion que rellena un array pasado por parametro 
*   con numero aleatorios del 0 al 9
*
* Param: INT* arr -> Puntero del array a rellenar
* Param: INT size -> Longitud del array
* Return: void
*/
__host__ void rellenarVectorHst( int *arr, int size ) 
{
    for ( size_t i = 0; i < size; i++ )
    {
        arr[i] = rand() % 10 ;
    }
}

/**
* Funcion: invertirVector
* Objetivo: Funcion que da la vuelta a un vector pasado por paramtro
*
* Param: INT* arr -> Puntero del array a invertir
* Param: INT size -> Longitud del array
* Return: void
*/
__global__ void invertirVector( int *arr, int size)
{
   
    int temporal;
    for ( int i = 0, x = size - 1; i < x; i++, x-- ) {
        temporal = arr[ i ];
        arr[ i ] = arr[ x ];
        arr[x] = temporal;
    }

   
}

/**
* Funcion: sumarArrays
* Objetivo: Funcion que da la vuelta a un vector pasado por paramtro
*
* Param: INT* primer_array -> Primer puntero del array que se quiere sumar  
* Param: INT* segundo_array -> Segundo puntero del array que se quiere sumar  
* Param: INT* array_sumado -> Puntero del array que va a contener el resultado 
* Return: void
*/
__global__ void sumarArrays( int* primer_array, int* segundo_array, int* array_sumado ) 
{
    int id = threadIdx.x;
    array_sumado[id] = primer_array[id] + segundo_array[id];
}


// MAIN: rutina principal ejecutada en el host
int main(int argc, char** argv)
{
    // Semilla de random aleatoria 
    srand(time(NULL));

    int cantidad_computo;

    // Obetener el dispisivo cuda
    int numero_dispositivos;
    cudaGetDeviceCount(&numero_dispositivos);
    if (numero_dispositivos != 0)
    {
        printf("Se han encontrado <%d> dispositivos CUDA:\n", numero_dispositivos);
        for (int i = 0; i < numero_dispositivos; i++)
        {
            propiedadesDispositivo( i, cantidad_computo );
        }
    }
    else
    {
        printf("!!!!!ERROR!!!!!\n");
        printf("Este ordenador no tiene dispositivo de ejecucion CUDA\n");
        printf("<pulsa [INTRO] para finalizar>");
        getchar();
        return 1;
    }
    
    // declaracion de variables
    int* hst_vector1, * hst_vector2, * hst_resultado;
    int* dev_vector1, * dev_vector2, * dev_resultado;

    int numero_elementos;
    bool is_numero_valido = false;
    bool is_cantidad_valida = false;

    do {

        do {

            printf("Introduce el numero de elementos: ");
            is_numero_valido = scanf( "%i", &numero_elementos );
            printf("\n");

        } while ( !is_numero_valido );

        if ( ( cantidad_computo > 1 && is_numero_valido < 512 ) || ( cantidad_computo > 2 && is_numero_valido < 1024 ) )
        {
            is_cantidad_valida = true;
        }else {
            printf("> ERROR: numero maximo de hilosd superado! [ %d hilos ]\n", cantidad_computo > 1 ? 512 : 1024 );
        }

    } while ( !is_cantidad_valida );

    printf("> Vector de %d elementos \n", is_numero_valido);
    printf("> Lanzamiento con 1 bloque de %d \n", numero_elementos);
    
    

    // reserva de memoria en el host
    hst_vector1 = ( int* )malloc( numero_elementos * sizeof( int ) );
    hst_vector2 = ( int* )malloc( numero_elementos * sizeof( int ) );
    hst_resultado = ( int* )malloc( numero_elementos * sizeof( int ) );

    // reserva de memoria en el device
    cudaMalloc( ( void** )&dev_vector1, numero_elementos * sizeof( int ) );
    cudaMalloc( ( void** )&dev_vector2, numero_elementos * sizeof( int ) );
    cudaMalloc( ( void** )&dev_resultado, numero_elementos * sizeof( int ) );

  
    // Rellenamos el vector con la funcion previamente creada
    rellenarVectorHst( hst_vector1, numero_elementos);

    // Copiamos el vector 1 en el device 2, esto es necesario ya que desde la funcion invertir solo podemos acceder 
    // a la memopria del reservada en el device 
    cudaMemcpy( dev_vector2, hst_vector1, numero_elementos * sizeof( int ), cudaMemcpyHostToDevice );
    // Invertimos el vector y ese mismo vector es el resultado
    invertirVector<<<1,1>>>( dev_vector2, numero_elementos );
    // Copiamos el contenido del vector device 2 al vector host 2
    cudaMemcpy( hst_vector2, dev_vector2, numero_elementos * sizeof( int ), cudaMemcpyDeviceToHost );
   

    // Mostrar vector 1
    printf( "VECTOR 1:\n" );
    for ( int i = 0; i < numero_elementos; i++ )
    {
        printf( "%i ", hst_vector1[ i ] );
    }
    printf( "\n" );

    // Mostrar vector 2
    printf("VECTOR 2:\n");
    for ( int i = 0; i < numero_elementos; i++ )
    {
        printf( "%i ", hst_vector2[ i ] );
    }
    printf("\n");


    // Sumar V1 + V2, aqui sucede lo mismo que antes para sumar los dos vectores es necesario 
    // copiar el contenido del vector host 1 a un vector que se encuentre en la memoria del device 
    // en este caso he utilizado la variable  dev_vector1
    cudaMemcpy( dev_vector1, hst_vector1, numero_elementos * sizeof( int ), cudaMemcpyHostToDevice );
    // Para sumar los dos vectores en vez de usar un bucle for he utilizado los N hilos 
    // siendo N el numero de huecos introducidos por el usuario 
    // para hacer esto es necesario comporbar que no sobrepasamos en numero de hilos 
    sumarArrays<<<1,numero_elementos>>>(dev_vector1, dev_vector2, dev_resultado );
    cudaMemcpy( hst_resultado, dev_resultado, numero_elementos * sizeof( int ), cudaMemcpyDeviceToHost );    // Mostrar resultado de la suma
    printf( "\nSUMA:\n", numero_elementos );
    for ( int i = 0; i < numero_elementos; i++ )
    {
        printf( "%i ", hst_resultado[ i ] );
    }
    printf("\n");


    // Salida del programa 
    time_t fecha;
    time(&fecha);
    printf("***************************************************\n");
    printf("Programa ejecutado el: %s\n", ctime(&fecha));
    printf("<pulsa [INTRO] para finalizar>");
    getchar();
    return 0;
}