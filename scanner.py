import cv2
from pyzbar.pyzbar import decode

camera = None

def scan_from_camera():
    global camera
    camera = cv2.VideoCapture(0)
    code = ""

    while True:
        success, frame = camera.read()
        if not success:
            break
        decoded_objs = decode(frame)
        if decoded_objs:
            code = decoded_objs[0].data.decode("utf-8")
            break
        cv2.imshow("Scanning - Press Q to Cancel", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    camera.release()
    cv2.destroyAllWindows()
    return code

def stop_scanning():
    global camera
    if camera is not None:
        camera.release()
        cv2.destroyAllWindows()
