using UnityEngine;
using UnityEngine.Rendering;

public class ColorGrading : MonoBehaviour
{
    [SerializeField] private VolumeProfile defaultVolume;
    [SerializeField] private VolumeProfile cold;
    [SerializeField] private VolumeProfile warm;
    [SerializeField] private VolumeProfile custom1;
    [SerializeField] private VolumeProfile custom2;
    private Volume _volume;

    private void Start()
    {
        _volume = GetComponent<Volume>();
    }

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Alpha5))
            _volume.profile = defaultVolume;
        if (Input.GetKeyDown(KeyCode.Alpha6))
            _volume.profile = cold;
        if (Input.GetKeyDown(KeyCode.Alpha7))
            _volume.profile = warm;
        if (Input.GetKeyDown(KeyCode.Alpha8))
            _volume.profile = custom1;
        if (Input.GetKeyDown(KeyCode.Alpha9))
            _volume.profile = custom2;
    }
}
