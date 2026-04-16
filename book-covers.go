package main

import (
    "bufio"
    "errors"
    "flag"
    "image"
    "image/color"
    "io"
    "log"
    "net/http"
    "os"
    "regexp"

    _ "image/jpeg"
    _ "image/png"

    "github.com/disintegration/imaging"
)

var debugMode *bool
var readmectl *string
var temporary *string

func init() {
    debugMode = flag.Bool("trace", true, "Ativa trace/debug")
    readmectl = flag.String("origin", "README.md", "Caminho para o arquivo markdown do catálogo")
    temporary = flag.String("temporary", "temporary.png", "Caminho para a capa temporária do livro")

    flag.Parse()
}

func trace(format string, args ...interface{}) {
    if !*debugMode {
        return
    }
    log.Printf("[TRACE] "+format, args...)
}

func main() {
    README, _ := os.Open(*readmectl)
    scanner := bufio.NewScanner(README)
    trace("reading from %s", *readmectl)

    re := regexp.MustCompile(`\[book\-(.*)\]: http(.*)`)

    for scanner.Scan() {
        if re.MatchString(scanner.Text()) {
            sub := re.FindStringSubmatch(scanner.Text())

            target := sub[1]
            source := sub[2]
            trace("found book entry target=%q source=%q", target, source)

            processImage(".../covers/" + target + ".png", "http" + source)
        }
    }
}

func processImage(target string, source string) {
    trace("processing image target=%s source=%s", target, source)
    downloadFile(source, *temporary)
    imgs, err := os.Open(*temporary)
    if err != nil {
        log.Fatalf("failed to open temporary image file: %v", err)
    }
    defer imgs.Close()

    src, err := imaging.Open(*temporary)
    if err != nil {
        log.Fatalf("failed to open image: %v", err)
    }

    imgData, _, err := image.DecodeConfig(imgs)
    if err != nil {
        log.Fatalf("failed to decode image config: %v", err)
    }

    src = imaging.CropAnchor(src, 300, 300, imaging.Center)
    src = imaging.Resize(src, 0, 200, imaging.Lanczos)
    prp := 20000 / imgData.Height
    dst := imaging.New(150, 200, color.NRGBA{0, 0, 0, 0})
    dst = imaging.Paste(dst, src, image.Pt(75-(imgData.Width*prp/100)/2, 0))
    trace("resized image width=%d height=%d prp=%d", imgData.Width, imgData.Height, prp)

    err = imaging.Save(dst, target)
    if err != nil {
        log.Fatalf("failed to save image: %v -- %s / %s", err, source, target)
    }
    trace("saved image to %s", target)

    err = os.Remove(*temporary)
    if err != nil {
        trace("failed to remove temporary file: %v", err)
    } else {
        trace("temporary file removed")
    }
}

func downloadFile(URL, fileName string) error {
    trace("downloading %s to %s", URL, fileName)
    response, err := http.Get(URL)
    if err != nil {
        return err
    }
    defer response.Body.Close()

    if response.StatusCode != 200 {
        return errors.New("Received non 200 response code")
    }
    file, err := os.Create(fileName)
    if err != nil {
        return err
    }
    defer file.Close()

    _, err = io.Copy(file, response.Body)
    if err != nil {
        return err
    }

    trace("download complete %s", fileName)
    return nil
}