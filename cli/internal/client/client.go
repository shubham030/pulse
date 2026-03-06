package client

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

type Client struct {
	baseURL string
	http    *http.Client
}

func New(host string, port int) *Client {
	return &Client{
		baseURL: fmt.Sprintf("http://%s:%d", host, port),
		http:    &http.Client{Timeout: 5 * time.Second},
	}
}

type TimerRequest struct {
	Duration int    `json:"duration"`
	Label    string `json:"label"`
	Sound    bool   `json:"sound"`
}

type OkResponse struct {
	OK    bool   `json:"ok"`
	Error string `json:"error,omitempty"`
}

type QueuedTimer struct {
	Duration int    `json:"duration"`
	Label    string `json:"label"`
	Sound    bool   `json:"sound"`
}

type PomodoroConfig struct {
	FocusMinutes          int `json:"focusMinutes"`
	ShortBreakMinutes     int `json:"shortBreakMinutes"`
	LongBreakMinutes      int `json:"longBreakMinutes"`
	CyclesBeforeLongBreak int `json:"cyclesBeforeLongBreak"`
	TotalCycles           int `json:"totalCycles"`
}

type PomodoroState struct {
	Config       PomodoroConfig `json:"config"`
	CurrentCycle int            `json:"currentCycle"`
	TotalCycles  int            `json:"totalCycles"`
	Phase        string         `json:"phase"`
}

type StatusResponse struct {
	Status    string         `json:"status"`
	Running   bool           `json:"running"`
	Paused    bool           `json:"paused"`
	Remaining int            `json:"remaining"`
	Total     int            `json:"total"`
	Label     string         `json:"label"`
	Queue     []QueuedTimer  `json:"queue"`
	Pomodoro  *PomodoroState `json:"pomodoro,omitempty"`
}

func (c *Client) post(path string, body any) error {
	var buf *bytes.Reader
	if body != nil {
		data, err := json.Marshal(body)
		if err != nil {
			return err
		}
		buf = bytes.NewReader(data)
	} else {
		buf = bytes.NewReader(nil)
	}

	resp, err := c.http.Post(c.baseURL+path, "application/json", buf)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	var ok OkResponse
	if err := json.NewDecoder(resp.Body).Decode(&ok); err != nil {
		return fmt.Errorf("decode response: %w", err)
	}
	if !ok.OK {
		return fmt.Errorf("server error: %s", ok.Error)
	}
	return nil
}

func (c *Client) delete(path string) error {
	req, err := http.NewRequest(http.MethodDelete, c.baseURL+path, nil)
	if err != nil {
		return err
	}
	resp, err := c.http.Do(req)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()
	return nil
}

func (c *Client) Start(req TimerRequest) error {
	return c.post("/timer", req)
}

func (c *Client) Stop() error {
	return c.post("/stop", nil)
}

func (c *Client) Pause() error {
	return c.post("/pause", nil)
}

func (c *Client) Resume() error {
	return c.post("/resume", nil)
}

func (c *Client) Skip() error {
	return c.post("/skip", nil)
}

func (c *Client) Enqueue(req TimerRequest) error {
	return c.post("/queue", req)
}

func (c *Client) ClearQueue() error {
	return c.delete("/queue")
}

func (c *Client) StartPomodoro(cfg PomodoroConfig) error {
	return c.post("/pomodoro", cfg)
}

func (c *Client) SetTheme(theme string) error {
	return c.post("/settings", map[string]string{"theme": theme})
}

func (c *Client) Status() (*StatusResponse, error) {
	resp, err := c.http.Get(c.baseURL + "/status")
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	var status StatusResponse
	if err := json.NewDecoder(resp.Body).Decode(&status); err != nil {
		return nil, fmt.Errorf("decode response: %w", err)
	}
	return &status, nil
}

func FormatDuration(seconds int) string {
	m := seconds / 60
	s := seconds % 60
	return fmt.Sprintf("%02d:%02d", m, s)
}
