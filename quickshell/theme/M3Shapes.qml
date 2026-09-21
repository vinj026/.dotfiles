pragma Singleton
import QtQuick
import Quickshell
import "../shapes/material/material-shapes.js" as MaterialShapes

Singleton {
    id: root

    // Curated 18 Material Design 3 Expressive Shapes for Workspaces
    readonly property var shapeGetters: [
        MaterialShapes.getCircle,         // 1. Circle
        MaterialShapes.getSquare,         // 2. Rounded Square
        MaterialShapes.getArch,           // 3. Bottom-Rounded / Arch
        MaterialShapes.getTriangle,       // 4. Blob Triangle
        MaterialShapes.getDiamond,        // 5. Irregular Diamond / Rounded Diamond
        MaterialShapes.getGem,            // 6. Rounded Hexagon
        MaterialShapes.getCookie9Sided,   // 7. Gear / Cog
        MaterialShapes.getCookie7Sided,   // 8. Scalloped Circle
        MaterialShapes.getPill,           // 9. Rounded Rectangle
        MaterialShapes.getBun,            // 10. Irregular Circle
        MaterialShapes.getSunny,          // 11. Jagged Circle
        MaterialShapes.getPuffy,          // 12. Irregular Blob
        MaterialShapes.getVerySunny,      // 13. Spiky Circle
        MaterialShapes.getBurst,          // 14. Starburst
        MaterialShapes.getBoom,           // 15. Jagged Star
        MaterialShapes.getSoftBurst,      // 16. Spiky Blob
        MaterialShapes.getSemiCircle,     // 17. Rounded Arch
        MaterialShapes.getClover8Leaf     // 18. Octagonal / Rounded Octagon
    ]

    readonly property int count: shapeGetters.length

    function getPolygon(index) {
        if (index < 0 || index >= shapeGetters.length) return shapeGetters[0]();
        return shapeGetters[index]();
    }

    function getRandomIndex(excludeIndex) {
        if (shapeGetters.length <= 1) return 0;
        var idx = Math.floor(Math.random() * shapeGetters.length);
        while (idx === excludeIndex) {
            idx = Math.floor(Math.random() * shapeGetters.length);
        }
        return idx;
    }
}
