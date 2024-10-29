using UnityEngine;

public class MaterialChanger : MonoBehaviour
{
    private Renderer _rend;
    
    [SerializeField] private Material lambertMaterial;
    [SerializeField] private Material specularMaterial;
    [SerializeField] private Material toonMaterial;
    private Material _originalMaterial;
    
    void Start()
    {
        _rend = GetComponent<Renderer>();
        
        _originalMaterial = _rend.material;
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Alpha1))
            _rend.material = _originalMaterial;
        if (Input.GetKeyDown(KeyCode.Alpha2))
            _rend.material = lambertMaterial;
        if (Input.GetKeyDown(KeyCode.Alpha3))
            _rend.material = specularMaterial;
        if (Input.GetKeyDown(KeyCode.Alpha4))
            _rend.material = toonMaterial;
    }
}
