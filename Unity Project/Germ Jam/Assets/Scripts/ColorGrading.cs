using UnityEngine;

public class ColorGrading : MonoBehaviour
{
    //[SerializeField] private Material[] lutMaterials;
    public Material lutMaterial;
    private int _index = 0;
    
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Debug.Log("OnRenderImage called");
        
        if (lutMaterial != null)
            Graphics.Blit(source, destination, lutMaterial);
        else
            Graphics.Blit(source, destination);
        
        //if (lutMaterials == null) return;
        
        //Graphics.Blit(source, destination, CurrentLut(_index));
    }

    /*
    private Material CurrentLut(int index)
    {
        return lutMaterials[index];
    }*/

    public void NoLut()
    {
        _index = 0;
    }

    public void WarmLut()
    {
        _index = 1;
    }

    public void ColdLut()
    {
        _index = 2;
    }

    public void Custom1Lut()
    {
        _index = 3;
    }

    public void Custom2Lut()
    {
        _index = 4;
    }
}
