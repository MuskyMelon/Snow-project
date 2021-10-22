using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class OldPerlinNoise : MonoBehaviour
{
    public float scale = 1.0f;

    public int pixWidth, pixHeight;
    public float xOrg, yOrg;

    public Texture2D noiseTexture;
    public Renderer rend;
    public Material perlinMaterial;
    public Shader heightShader;
    private Color[] pix;

    // Start is called before the first frame update
    void Start()
    {
        print(pixWidth);
        noiseTexture = new Texture2D(pixWidth, pixHeight);

        pix = new Color[pixWidth * pixHeight];

        rend = this.GetComponent<Renderer>();
        Noise();

        perlinMaterial = new Material(heightShader);
        perlinMaterial.SetTexture("_DispTex", noiseTexture);
        perlinMaterial.SetTexture("_MainTex", noiseTexture);

        rend.material = perlinMaterial;

    }

    void Noise()
    {
        for (float y = 0; y < pixHeight; y++)
        {
            for (float x = 0; x < pixWidth; x++)
            {

                float xCoord = xOrg + x / noiseTexture.width * scale;
                float yCoord = yOrg + y / noiseTexture.height * scale;
                float noise = Mathf.PerlinNoise(xCoord, yCoord);
                pix[(int)y * noiseTexture.width + (int)x] = new Color(noise, 0, 0);

            }
        }
        noiseTexture.SetPixels(pix);
        noiseTexture.Apply();
    }

    private void OnGUI()
    {
        //GUI.DrawTexture(new Rect(256, 0, 256, 256), noiseTexture, ScaleMode.ScaleToFit, false, 1);
    }
}
