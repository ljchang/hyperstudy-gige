#include <arv.h>
#include <stdio.h>
#include <stdlib.h>

static void
new_buffer_cb (ArvStream *stream, gpointer user_data)
{
    ArvBuffer *buffer;
    
    buffer = arv_stream_try_pop_buffer (stream);
    if (buffer != NULL) {
        if (arv_buffer_get_status (buffer) == ARV_BUFFER_STATUS_SUCCESS) {
            printf ("Frame received!\n");
        }
        arv_stream_push_buffer (stream, buffer);
    }
}

int main(int argc, char **argv)
{
    ArvCamera *camera;
    ArvStream *stream;
    GError *error = NULL;
    
    /* Connect to the first available camera */
    camera = arv_camera_new (NULL, &error);
    
    if (ARV_IS_CAMERA (camera)) {
        printf ("Connected to %s\n", arv_camera_get_model_name (camera, NULL));
        
        /* Create a new stream */
        stream = arv_camera_create_stream (camera, NULL, NULL, &error);
        
        if (ARV_IS_STREAM (stream)) {
            int i;
            size_t payload;
            
            /* Push some buffers in the stream input buffer queue */
            payload = arv_camera_get_payload (camera, &error);
            for (i = 0; i < 5; i++)
                arv_stream_push_buffer (stream, arv_buffer_new (payload, NULL));
            
            /* Start the acquisition */
            arv_camera_start_acquisition (camera, &error);
            
            /* Connect the new-buffer signal */
            g_signal_connect (stream, "new-buffer", G_CALLBACK (new_buffer_cb), NULL);
            
            /* Wait 5 seconds, letting the callback run */
            g_usleep (5000000);
            
            /* Stop the acquisition */
            arv_camera_stop_acquisition (camera, &error);
            
            g_object_unref (stream);
        }
        
        g_object_unref (camera);
    }
    
    return 0;
}