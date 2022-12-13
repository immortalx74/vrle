    vec4 lovrmain()
    {
		PointSize = 10.0f;
        return Projection * View * Transform * VertexPosition;
    }