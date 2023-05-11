#include <stdio.h>
#include <stdint.h>
#include <math.h>


#define POINTS 8
#define PI 3.14159265358979323846

typedef int32_t rotation_factor_t;


/**
 * @brief generate a array of rotation_factor
 * @param array return array 
 * @param len  length of array 
 * @param factor magnification of factor
 */
void CreateRoArray(rotation_factor_t *array, int len, int factor)
{
    double angle = 0;
    for (int i = 0; i < len; i+=2) {
        angle = PI * i / len;
        array[i]   = (rotation_factor_t)(cos(angle) * factor);
        array[i+1] = (rotation_factor_t)(sin(angle) * factor);
    }
}

int main() {

    static rotation_factor_t ro_array[POINTS] = {0};

    CreateRoArray(ro_array, POINTS, 512);

    printf("rotation factor:");
    for (int i = 0; i < POINTS; i++) {
        printf("%d,",ro_array[i]);
    }


    return 0;
}
